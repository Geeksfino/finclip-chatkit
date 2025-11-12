/**
 * LLM Agent - Integrates with LiteLLM or DeepSeek
 */

import { BaseAgent } from './base.js';
import type {
  RunAgentInput,
  BaseEvent,
  Message,
  Tool,
  AssistantMessage,
  ToolMessage,
  RunStartedEvent,
  RunFinishedEvent,
  RunErrorEvent,
  TextMessageChunkEvent,
  TextMessageStartEvent,
  TextMessageEndEvent,
  ToolCallStartEvent,
  ToolCallArgsEvent,
  ToolCallEndEvent,
} from '@ag-ui/core';
import { EventType } from '@ag-ui/core';
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

interface ToolConversionResult {
  tools: any[];
  sanitizedToOriginal: Map<string, string>;
  originalToSanitized: Map<string, string>;
}

interface ChatMessage {
  role: string;
  content: string;
  tool_calls?: any[];
  tool_call_id?: string;
}

interface ChatCompletionChunk {
  choices: Array<{
    delta: {
      content?: string;
      tool_calls?: Array<{
        id?: string;
        function?: {
          name?: string;
          arguments?: string;
        };
      }>;
    };
    finish_reason?: string;
  }>;
}

const SYSTEM_PROMPT = 'You are a helpful assistant.';

export class LLMAgent extends BaseAgent {
  private readonly maxRetries: number;
  private readonly retryDelayMs: number;
  private readonly timeoutMs: number;

  constructor(private config: LLMConfig) {
    super();
    this.maxRetries = config.maxRetries ?? 2;
    this.retryDelayMs = config.retryDelayMs ?? 1000;
    this.timeoutMs = config.timeoutMs ?? 30000;
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
          await new Promise(resolve => setTimeout(resolve, delayMs));
        }
      }
    }

    throw lastError || new Error('Fetch failed after retries');
  }

  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages, tools, context } = input;

    logger.info(
      { 
        threadId, 
        runId, 
        model: this.config.model,
        messageCount: messages.length,
        toolCount: tools?.length || 0,
      },
      'Running LLM agent'
    );

    // Start run
    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    try {
      // Note: This is a demo server without real tool implementations.
      // Tools are received from the client but not passed to the LLM.
      // In a production system, tools would be:
      // 1. Looked up in a tool registry
      // 2. Converted to proper JSON Schema format
      // 3. Passed to the LLM for parameter inference
      // 4. Executed via MCP or other mechanism
      // 5. Results fed back to the LLM
      
      // For now, we include tool info in the context summary for awareness
      const contextSummary = this.getContextSummaryLines(context);
      
      // Add available tools to context summary (informational only)
      if (tools?.length) {
        contextSummary.push(`Available tools: ${tools.map(t => t.name).join(', ')}`);
        logger.debug(
          { 
            threadId, 
            runId, 
            toolCount: tools.length,
            toolNames: tools.map(t => t.name),
          },
          'Tools available (not passed to LLM in demo mode)'
        );
      }

      // Build full chat message sequence including system prompt and context summary
      const chatMessages = this.buildChatMessages(
        messages,
        contextSummary,
        undefined // No tool name sanitization needed
      );
      logger.debug(
        { threadId, runId, messageCount: chatMessages.length },
        'Converted messages to OpenAI format'
      );

      // Call LLM API (without tools - demo mode)
      const requestBody = {
        model: this.config.model,
        messages: chatMessages,
        stream: true,
        temperature: this.config.temperature ?? 0.7,
      };

      this.logPrompt(
        threadId,
        runId,
        chatMessages,
        context,
        contextSummary,
        undefined // No tool conversion in demo mode
      );

      logger.debug(
        {
          threadId,
          runId,
          endpoint: this.config.endpoint,
          requestBody: JSON.stringify(requestBody),
          maxRetries: this.maxRetries,
          timeoutMs: this.timeoutMs,
        },
        'Sending request to LLM API'
      );

      const response = await this.fetchWithRetry(
        `${this.config.endpoint}/chat/completions`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.config.apiKey}`,
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
            requestBody: JSON.stringify(requestBody),
          },
          'LLM API returned error response'
        );
        throw new Error(
          `LLM API error: ${response.status} ${response.statusText}. Body: ${errorBody}`
        );
      }

      logger.debug(
        { threadId, runId },
        'Received successful response from LLM API, starting to parse stream'
      );

      // Stream the response
      const messageId = this.generateMessageId();
      let currentToolCall: { id: string; name: string; args: string } | null = null;
      let textMessageStarted = false;

      for await (const chunk of this.parseSSEStream(response.body!)) {
        if (!chunk.choices?.[0]?.delta) continue;

        const delta = chunk.choices[0].delta;

        // Handle text content
        if (delta.content) {
          // Send TEXT_MESSAGE_START before first chunk
          if (!textMessageStarted) {
            const startEvt: TextMessageStartEvent = {
              type: EventType.TEXT_MESSAGE_START,
              messageId,
              role: 'assistant',
            };
            yield startEvt;
            textMessageStarted = true;
          }

          const chunkEvt: TextMessageChunkEvent = {
            type: EventType.TEXT_MESSAGE_CHUNK,
            messageId,
            delta: delta.content,
          };
          yield chunkEvt;
        }

        // Handle tool calls
        if (delta.tool_calls?.[0]) {
          const toolCall = delta.tool_calls[0];

          if (toolCall.id) {
            // Start new tool call
            if (currentToolCall) {
              // End previous tool call
              const endPrev: ToolCallEndEvent = {
                type: EventType.TOOL_CALL_END,
                toolCallId: currentToolCall.id,
              };
              yield endPrev;
            }

            const sanitizedName = toolCall.function?.name || '';
            // In demo mode, no tool name sanitization
            const originalName = sanitizedName;

            currentToolCall = {
              id: toolCall.id,
              name: originalName,
              args: '',
            };

            const startCall: ToolCallStartEvent = {
              type: EventType.TOOL_CALL_START,
              toolCallId: currentToolCall.id,
              toolCallName: currentToolCall.name,
              parentMessageId: messageId,
            };
            yield startCall;
          }

          // Accumulate arguments
          if (toolCall.function?.arguments && currentToolCall) {
            currentToolCall.args += toolCall.function.arguments;
            const argsEvt: ToolCallArgsEvent = {
              type: EventType.TOOL_CALL_ARGS,
              toolCallId: currentToolCall.id,
              delta: toolCall.function.arguments,
            };
            yield argsEvt;
          }
        }
      }

      // End any pending tool call
      if (currentToolCall) {
        const endEvt: ToolCallEndEvent = {
          type: EventType.TOOL_CALL_END,
          toolCallId: currentToolCall.id,
        };
        yield endEvt;
      }

      // Send TEXT_MESSAGE_END if we started a text message
      if (textMessageStarted) {
        const endEvt: TextMessageEndEvent = {
          type: EventType.TEXT_MESSAGE_END,
          messageId,
        };
        yield endEvt;
      }

      // Finish run
      const finished: RunFinishedEvent = {
        type: EventType.RUN_FINISHED,
        threadId,
        runId,
      };
      yield finished;
    } catch (error) {
      // Enhanced error logging with full details
      const errorDetails: any = {
        threadId,
        runId,
        messageCount: messages.length,
        toolCount: tools?.length || 0,
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        errorName: error instanceof Error ? error.name : 'UnknownError',
      };

      // Add stack trace if available
      if (error instanceof Error && error.stack) {
        errorDetails.stack = error.stack;
      }

      // Add input details for debugging
      if (tools && tools.length > 0) {
        errorDetails.tools = tools.map(t => ({
          name: t.name,
          description: t.description,
        }));
      }

      // Log the full error for debugging
      logger.error(errorDetails, 'LLM agent error - detailed information');

      const errorEvt: RunErrorEvent = {
        type: EventType.RUN_ERROR,
        message: error instanceof Error ? error.message : 'Unknown error',
      };
      yield errorEvt;
    }
  }

  private convertMessages(
    messages: Message[],
    nameMap?: Map<string, string>
  ): ChatMessage[] {
    const mapRole = (role: string): string => {
      switch (role) {
        case 'agent':
          return 'assistant';
        case 'client':
          return 'user';
        default:
          return role;
      }
    };

    const isSupportedRole = (role: string): boolean =>
      role === 'system' || role === 'user' || role === 'assistant' || role === 'tool';

    return messages.map((msg, index) => {
      try {
        const content =
          'content' in msg && typeof (msg as any).content === 'string'
            ? ((msg as any).content as string)
            : '';

        const mappedRole = mapRole(msg.role);
        if (!isSupportedRole(mappedRole)) {
          logger.warn(
            { messageIndex: index, originalRole: msg.role, mappedRole },
            'Unsupported role detected when converting message; defaulting to "user"'
          );
        }

        const chatMessage: ChatMessage = {
          role: isSupportedRole(mappedRole) ? mappedRole : 'user',
          content,
        };

        if (msg.role === 'assistant') {
          const assistantMsg = msg as AssistantMessage;
          if (assistantMsg.toolCalls) {
            chatMessage.tool_calls = assistantMsg.toolCalls.map((toolCall) => {
              const originalName = toolCall.function.name;
              const sanitizedName = nameMap?.get(originalName) ?? originalName;
              return {
                id: toolCall.id,
                type: 'function',
                function: {
                  name: sanitizedName,
                  arguments: toolCall.function.arguments ?? '',
                },
              };
            });
          }
        }

        if (msg.role === 'tool') {
          const toolMsg = msg as ToolMessage;
          if (toolMsg.toolCallId) {
            chatMessage.tool_call_id = toolMsg.toolCallId;
          }
        }

        return chatMessage;
      } catch (error) {
        logger.error(
          {
            messageIndex: index,
            messageRole: msg.role,
            error: error instanceof Error ? error.message : 'Unknown error',
          },
          'Error converting message to OpenAI format'
        );
        throw error;
      }
    });
  }

  private buildChatMessages(
    messages: Message[],
    contextSummary: string[],
    nameMap?: Map<string, string>
  ): ChatMessage[] {
    const sequence: ChatMessage[] = [
      {
        role: 'system',
        content: SYSTEM_PROMPT,
      },
    ];

    /*
    if (contextSummary.length > 0) {
      const summaryContent = ['Context summary:', ...contextSummary.map((line) => `- ${line}`)].join('\n');
      sequence.push({
        role: 'user',
        content: summaryContent,
      });
    }
    */
   
    const converted = this.convertMessages(messages, nameMap);
    sequence.push(...converted);
    return sequence;
  }

  private convertTools(tools: Tool[]): ToolConversionResult {
    const usedNames = new Set<string>();
    const sanitizedToOriginal = new Map<string, string>();
    const originalToSanitized = new Map<string, string>();

    const converted = tools.map((tool, index) => {
      try {
        const sanitizedName = this.sanitizeToolName(tool.name, usedNames);
        sanitizedToOriginal.set(sanitizedName, tool.name);
        originalToSanitized.set(tool.name, sanitizedName);

        if (sanitizedName !== tool.name) {
          logger.debug(
            {
              originalName: tool.name,
              sanitizedName,
            },
            'Sanitized tool name to comply with provider requirements'
          );
        }

        return {
          type: 'function',
          function: {
            name: sanitizedName,
            description: tool.description,
            parameters: tool.parameters,
          },
        };
      } catch (error) {
        logger.error(
          {
            toolIndex: index,
            toolName: tool.name,
            error: error instanceof Error ? error.message : 'Unknown error',
          },
          'Error converting tool to OpenAI format'
        );
        throw error;
      }
    });

    return {
      tools: converted,
      sanitizedToOriginal,
      originalToSanitized,
    };
  }

  private sanitizeToolName(name: string, usedNames: Set<string>): string {
    const pattern = /[^a-zA-Z0-9_-]/g;
    const baseCandidate = name.replace(pattern, '_');
    const base = baseCandidate.length > 0 ? baseCandidate : 'tool';

    let finalName = base;
    let counter = 1;
    while (usedNames.has(finalName)) {
      counter++;
      finalName = `${base}_${counter}`;
    }

    usedNames.add(finalName);
    return finalName;
  }

  private getContextSummaryLines(context: RunAgentInput['context']): string[] {
    if (!context || context.length === 0) {
      return [];
    }

    const previewLimit = 200;
    const lines: string[] = [];

    for (const entry of context as any[]) {
      const key = entry?.key ?? 'unknown';
      const description = typeof entry?.value?.description === 'string'
        ? entry.value.description as string
        : undefined;

      if (description && description.length > 0) {
        lines.push(description);
        continue;
      }

      if (entry?.value?.data !== undefined) {
        try {
          const serialized = JSON.stringify(entry.value.data);
          const trimmed = serialized.length > previewLimit
            ? `${serialized.slice(0, previewLimit)}…`
            : serialized;
          lines.push(`${key}: ${trimmed}`);
        } catch {
          lines.push(`${key}: [unserializable data]`);
        }
        continue;
      }

      lines.push(`Context ${key} provided.`);
    }

    return lines;
  }

  private logPrompt(
    threadId: string,
    runId: string,
    messages: ChatMessage[],
    context: RunAgentInput['context'],
    contextSummary: string[],
    toolConversion?: ToolConversionResult
  ): void {
    const previewLimit = 200;
    const sanitizedMap = toolConversion?.sanitizedToOriginal;

    const logMessages = messages.map((message) => {
      const content = message.content ?? '';
      const formatted: Record<string, unknown> = {
        role: message.role,
        content:
          content.length > previewLimit
            ? `${content.slice(0, previewLimit)}…`
            : content,
      };

      if (message.tool_calls?.length) {
        formatted.toolCalls = message.tool_calls.map((toolCall) => {
          const sanitizedName = toolCall.function?.name || '';
          const originalName = sanitizedMap?.get(sanitizedName) ?? sanitizedName;
          return {
            id: toolCall.id,
            name: originalName,
            sanitizedName,
            hasArguments: Boolean(toolCall.function?.arguments),
          };
        });
      }

      if (message.tool_call_id) {
        formatted.toolCallId = message.tool_call_id;
      }

      return formatted;
    });

    const contextLog = context?.map((ctx) => {
      const description =
        typeof (ctx as any).value?.description === 'string'
          ? (ctx as any).value.description
          : undefined;
      const data = (ctx as any).value?.data;
      let dataPreview: string | undefined;
      if (data !== undefined) {
        try {
          const serialized = JSON.stringify(data);
          dataPreview =
            serialized.length > previewLimit
              ? `${serialized.slice(0, previewLimit)}…`
              : serialized;
        } catch (error) {
          dataPreview = '[unserializable]';
        }
      }

      return {
        key: (ctx as any).key,
        hasDescription: Boolean(description),
        description:
          description && description.length > previewLimit
            ? `${description.slice(0, previewLimit)}…`
            : description,
        hasData: data !== undefined,
        dataPreview,
      };
    });

    const toolsLog = toolConversion?.tools.map((tool) => {
      const sanitizedName = tool.function?.name || '';
      const originalName = sanitizedMap?.get(sanitizedName) ?? sanitizedName;
      return {
        name: originalName,
        sanitizedName,
        description: tool.function?.description,
      };
    });

    logger.info(
      {
        threadId,
        runId,
        messages: logMessages,
        contextSummary,
        context: contextLog,
        tools: toolsLog,
      },
      'Prepared LLM request payload'
    );
  }

  private async *parseSSEStream(
    body: ReadableStream<Uint8Array>
  ): AsyncGenerator<ChatCompletionChunk> {
    const reader = body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let chunkCount = 0;

    try {
      while (true) {
        const { done, value } = await reader.read();
        if (done) {
          logger.debug({ chunkCount }, 'Finished parsing SSE stream');
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
              chunkCount++;
              yield chunk;
            } catch (error) {
              logger.warn(
                {
                  line,
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
          chunkCount,
        },
        'Error while parsing SSE stream'
      );
      throw error;
    } finally {
      reader.releaseLock();
    }
  }
}
