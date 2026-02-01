/**
 * LLM Agent - Generates A2UI messages using Gemini or DeepSeek
 */

import { BaseAgent } from './base.js';
import type { A2UIRequest, A2UIMessage } from '../types/a2ui.js';
import { selectCatalog, STANDARD_CATALOG_ID } from '../constants/catalog.js';
import { fetch } from 'undici';
import type { Response } from 'undici';
import { logger } from '../utils/logger.js';

interface LLMConfig {
  endpoint: string;
  apiKey: string;
  model: string;
  temperature?: number;
  maxRetries?: number;
  retryDelayMs?: number;
  timeoutMs?: number;
}

interface ChatMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

interface ChatCompletionChunk {
  choices: Array<{
    delta: {
      content?: string;
    };
    finish_reason?: string;
  }>;
}

const SYSTEM_PROMPT_BASE = `You are an AI agent that generates A2UI (Agent to UI) protocol v0.8 messages.
Your responses must be valid A2UI JSONL format - each line is a complete JSON object.

A2UI message types:
1. surfaceUpdate - Define UI components (flat adjacency list)
2. dataModelUpdate - Update data model for data binding
3. beginRendering - Signal client to render (must come last)
4. deleteSurface - Remove a surface

Standard catalog (${STANDARD_CATALOG_ID}):
- Text: text (literalString/path), usageHint
- Button: child, action (name, context array with key/value)
- Row/Column: children (explicitList or template), alignment, distribution
- Card: child
- List: children (explicitList or template), direction, alignment
- TextField: label, text (NOT "value" - use "text" for input value), textFieldType, validationRegexp
- DateTimeInput: value, enableDate, enableTime, outputFormat
- template: dataBinding (string path e.g. "/items"), componentId

CRITICAL: TextField uses "text" property for the input value, NOT "value". DateTimeInput uses "value".

Example flow:
{"surfaceUpdate":{"surfaceId":"main","components":[{"id":"root","component":{"Column":{"children":{"explicitList":["text1"]}}}}]}}
{"surfaceUpdate":{"surfaceId":"main","components":[{"id":"text1","component":{"Text":{"text":{"literalString":"Hello"}}}}]}}
{"dataModelUpdate":{"surfaceId":"main","contents":[]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}

Always generate complete, valid A2UI messages. Only use components from the standard catalog.`;

export class LLMAgent extends BaseAgent {
  private readonly maxRetries: number;
  private readonly retryDelayMs: number;
  private readonly timeoutMs: number;

  constructor(private llmConfig: LLMConfig) {
    super();
    this.maxRetries = llmConfig.maxRetries ?? 2;
    this.retryDelayMs = llmConfig.retryDelayMs ?? 1000;
    this.timeoutMs = llmConfig.timeoutMs ?? 30000;
  }

  /**
   * Fetch with retry logic and timeout
   */
  private async fetchWithRetry(
    url: string,
    options: any
  ): Promise<Response> {
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);

        try {
          const response = await fetch(url, {
            ...options,
            signal: controller.signal,
          });
          clearTimeout(timeoutId);
          return response;
        } finally {
          clearTimeout(timeoutId);
        }
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));

        if (attempt < this.maxRetries) {
          const delayMs = this.retryDelayMs * Math.pow(2, attempt);
          logger.warn(
            {
              attempt: attempt + 1,
              maxRetries: this.maxRetries,
              delayMs,
              error: lastError.message,
            },
            'Fetch failed, retrying with exponential backoff'
          );
          await new Promise((resolve) => setTimeout(resolve, delayMs));
        }
      }
    }

    throw lastError || new Error('Fetch failed after retries');
  }

  async *run(input: A2UIRequest): AsyncGenerator<A2UIMessage> {
    const { threadId, runId, message, surfaceId } = input;

    logger.info(
      {
        threadId,
        runId,
        model: this.llmConfig.model,
        messageLength: message.length,
      },
      'Running LLM agent'
    );

    const targetSurfaceId = surfaceId || 'main';
    const catalogId = selectCatalog(input.metadata?.a2uiClientCapabilities);
    const supportedIds = input.metadata?.a2uiClientCapabilities?.supportedCatalogIds;
    const catalogHint =
      supportedIds && supportedIds.length > 0
        ? `\nClient supported catalogs: ${supportedIds.join(', ')}. Use only components from these catalogs.`
        : '';
    const systemPrompt = SYSTEM_PROMPT_BASE + catalogHint;

    try {
      // Build chat messages
      const chatMessages: ChatMessage[] = [
        { role: 'system', content: systemPrompt },
        {
          role: 'user',
          content: `Generate A2UI messages for the following user request. Respond with JSONL format (one JSON object per line). Each line must be a valid JSON object representing an A2UI message (surfaceUpdate, dataModelUpdate, beginRendering, or deleteSurface):\n\nUser request: ${message}`,
        },
      ];

      // Call LLM API
      const requestBody: any = {
        model: this.llmConfig.model,
        messages: chatMessages,
        stream: true,
        temperature: this.llmConfig.temperature ?? 0.7,
        // Note: Not all LLMs support response_format, so we'll parse JSONL from text stream
      };

      logger.debug(
        {
          threadId,
          runId,
          endpoint: this.llmConfig.endpoint,
          model: this.llmConfig.model,
        },
        'Sending request to LLM API'
      );

      // Call LLM API (OpenAI-compatible format)
      // Note: Gemini support can be added later with different endpoint handling
      const response = await this.fetchWithRetry(
        `${this.llmConfig.endpoint}/chat/completions`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.llmConfig.apiKey}`,
          },
          body: JSON.stringify(requestBody),
        }
      );

      if (!response.ok) {
        const errorBody = await response.text().catch(() => 'Unable to read error body');
        logger.error(
          {
            threadId,
            runId,
            status: response.status,
            statusText: response.statusText,
            errorBody,
          },
          'LLM API returned error response'
        );
        throw new Error(
          `LLM API error: ${response.status} ${response.statusText}. Body: ${errorBody}`
        );
      }

      // Parse streaming response and convert to A2UI messages
      let buffer = '';
      let accumulatedContent = '';

      for await (const chunk of this.parseSSEStream(response.body!)) {
        if (!chunk.choices?.[0]?.delta) continue;

        const delta = chunk.choices[0].delta;

        if (delta.content) {
          accumulatedContent += delta.content;
          buffer += delta.content;

          // Try to parse complete JSONL lines
          const lines = buffer.split('\n');
          buffer = lines.pop() || '';

          for (const line of lines) {
            const trimmed = line.trim();
            if (!trimmed || trimmed.startsWith('//')) continue;

            try {
              const message = JSON.parse(trimmed) as A2UIMessage;
              const enrichedMessage = this.enrichMessage(message, targetSurfaceId, catalogId);
              yield enrichedMessage;
            } catch (parseError) {
              // Not a complete JSON yet, continue accumulating
              logger.debug(
                { line: trimmed.substring(0, 100), error: parseError },
                'Failed to parse line as JSON (may be incomplete)'
              );
            }
          }
        }
      }

      // Process remaining buffer
      if (buffer.trim()) {
        try {
          const message = JSON.parse(buffer.trim()) as A2UIMessage;
          const enrichedMessage = this.enrichMessage(message, targetSurfaceId, catalogId);
          yield enrichedMessage;
        } catch (parseError) {
          logger.warn(
            { buffer: buffer.substring(0, 200), error: parseError },
            'Failed to parse final buffer as JSON'
          );
        }
      }

      // If no messages were generated, create a default response
      if (accumulatedContent.trim() === '') {
        logger.warn({ threadId, runId }, 'LLM returned empty response, generating default UI');
        yield* this.generateDefaultUI(targetSurfaceId, catalogId);
      }
    } catch (error) {
      logger.error(
        {
          threadId,
          runId,
          error: error instanceof Error ? error.message : 'Unknown error',
          stack: error instanceof Error ? error.stack : undefined,
        },
        'LLM agent error'
      );

      // Generate error UI
      yield* this.generateErrorUI(
        targetSurfaceId,
        error instanceof Error ? error.message : 'Unknown error',
        catalogId
      );
    }
  }

  /**
   * Parse SSE stream from LLM API
   */
  private async *parseSSEStream(
    body: ReadableStream<Uint8Array>
  ): AsyncGenerator<ChatCompletionChunk> {
    const reader = body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          logger.debug('Finished parsing SSE stream');
          break;
        }

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() || '';

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.slice(6);
            if (data === '[DONE]') {
              logger.debug('Received [DONE] marker from SSE stream');
              continue;
            }

            try {
              const chunk = JSON.parse(data);
              yield chunk;
            } catch (error) {
              logger.warn(
                {
                  line: line.substring(0, 100),
                  error: error instanceof Error ? error.message : 'Unknown error',
                },
                'Failed to parse SSE chunk'
              );
            }
          }
        }
      }
    } catch (error) {
      logger.error(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
          stack: error instanceof Error ? error.stack : undefined,
        },
        'Error while parsing SSE stream'
      );
      throw error;
    } finally {
      reader.releaseLock();
    }
  }

  /**
   * Enrich message with surfaceId and catalogId (for beginRendering)
   * Per A2UI v0.8: catalogId tells client which catalog to use
   */
  private enrichMessage(
    message: A2UIMessage,
    surfaceId: string,
    catalogId: string
  ): A2UIMessage {
    if ('surfaceUpdate' in message) {
      return {
        surfaceUpdate: {
          ...message.surfaceUpdate,
          surfaceId: message.surfaceUpdate.surfaceId || surfaceId,
        },
      };
    }

    if ('dataModelUpdate' in message) {
      return {
        dataModelUpdate: {
          ...message.dataModelUpdate,
          surfaceId: message.dataModelUpdate.surfaceId || surfaceId,
        },
      };
    }

    if ('beginRendering' in message) {
      return {
        beginRendering: {
          ...message.beginRendering,
          surfaceId: message.beginRendering.surfaceId || surfaceId,
          catalogId: message.beginRendering.catalogId ?? catalogId,
        },
      };
    }

    if ('deleteSurface' in message) {
      return {
        deleteSurface: {
          ...message.deleteSurface,
          surfaceId: message.deleteSurface.surfaceId || surfaceId,
        },
      };
    }

    return message;
  }

  /**
   * Generate default UI when LLM fails
   */
  private async *generateDefaultUI(
    surfaceId: string,
    catalogId: string
  ): AsyncGenerator<A2UIMessage> {
    yield {
      surfaceUpdate: {
        surfaceId,
        components: [
          {
            id: 'root',
            component: {
              Column: {
                children: {
                  explicitList: ['error-text'],
                },
              },
            },
          },
          {
            id: 'error-text',
            component: {
              Text: {
                text: {
                  literalString: 'I received your message. How can I help you?',
                },
              },
            },
          },
        ],
      },
    };

    yield {
      dataModelUpdate: {
        surfaceId,
        contents: [],
      },
    };

    yield {
      beginRendering: {
        surfaceId,
        root: 'root',
        catalogId,
      },
    };
  }

  /**
   * Generate error UI
   */
  private async *generateErrorUI(
    surfaceId: string,
    errorMessage: string,
    catalogId: string
  ): AsyncGenerator<A2UIMessage> {
    yield {
      surfaceUpdate: {
        surfaceId,
        components: [
          {
            id: 'root',
            component: {
              Column: {
                children: {
                  explicitList: ['error-text'],
                },
              },
            },
          },
          {
            id: 'error-text',
            component: {
              Text: {
                text: {
                  literalString: `Error: ${errorMessage}`,
                },
              },
            },
          },
        ],
      },
    };

    yield {
      dataModelUpdate: {
        surfaceId,
        contents: [],
      },
    };

    yield {
      beginRendering: {
        surfaceId,
        root: 'root',
        catalogId,
      },
    };
  }
}
