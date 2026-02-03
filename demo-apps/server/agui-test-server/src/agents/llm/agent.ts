/**
 * LLM Agent - Integrates with LLM providers and MCPUI/A2UI (optional)
 */

import { BaseAgent } from '../base.js';
import type {
  RunAgentInput,
  BaseEvent,
  RunStartedEvent,
  RunFinishedEvent,
  RunErrorEvent,
  TextMessageChunkEvent,
  TextMessageStartEvent,
  TextMessageEndEvent,
  ToolCallStartEvent,
  ToolCallArgsEvent,
  ToolCallEndEvent,
  ToolCallResultEvent,
} from '@ag-ui/core';
import { EventType } from '@ag-ui/core';
import { fetch } from 'undici';
import type { Response } from 'undici';
import { logger } from '../../utils/logger.js';
import { parseToolArgs, getErrorMessage } from '../../utils/helpers.js';
import type { OpenAITool } from '../../mcp/types.js';
import { streamA2UIPayloads } from '../../a2ui/index.js';
import { A2UI_CONSTANTS, CUSTOM_EVENT_NAMES } from '../../constants.js';
import { extractA2UIForwardedProps, createA2UICustomEvent } from '../../a2ui/utils.js';
import type {
  LLMConfig,
  MCPIntegration,
  A2UIIntegration,
} from './types.js';
import { parseSSEStream } from './sse-parser.js';
import { convertTools } from './tool-utils.js';
import {
  buildChatMessages,
  getContextSummaryLines,
  logPrompt,
} from './message-utils.js';

export class LLMAgent extends BaseAgent {
  private readonly maxRetries: number;
  private readonly retryDelayMs: number;
  private readonly timeoutMs: number;
  private readonly mcpIntegration?: MCPIntegration;
  private readonly a2uiIntegration?: A2UIIntegration;

  constructor(
    private llmConfig: LLMConfig,
    mcpIntegration?: MCPIntegration,
    a2uiIntegration?: A2UIIntegration
  ) {
    super();
    this.maxRetries = llmConfig.maxRetries ?? 2;
    this.retryDelayMs = llmConfig.retryDelayMs ?? 1000;
    this.timeoutMs = llmConfig.timeoutMs ?? 30000;
    this.mcpIntegration = mcpIntegration;
    this.a2uiIntegration = a2uiIntegration;
  }

  private async *emitA2UIToolResultAndPayloads(
    toolCall: { id: string; name: string; args: string },
    input: RunAgentInput
  ): AsyncGenerator<BaseEvent> {
    if (!this.a2uiIntegration) return;

    const resultMessageId = this.generateMessageId();
    const { threadId, runId } = input;
    const { metadata, surfaceId } = extractA2UIForwardedProps(input.forwardedProps);

    try {
      const parsedArgs = parseToolArgs(toolCall.args);
      const message = typeof parsedArgs.message === 'string' ? parsedArgs.message : '';

      yield {
        type: EventType.TOOL_CALL_RESULT,
        toolCallId: toolCall.id,
        messageId: resultMessageId,
        content: 'Generated interactive UI',
        role: 'tool',
      } as ToolCallResultEvent;

      for await (const payload of streamA2UIPayloads(
        this.a2uiIntegration.serverUrl,
        { message, threadId, runId, surfaceId, metadata },
        this.a2uiIntegration.timeoutMs
      )) {
        yield createA2UICustomEvent(threadId, payload);
      }
    } catch (error) {
      const errorMsg = getErrorMessage(error);
      logger.warn(
        { toolCallId: toolCall.id, toolName: toolCall.name, error: errorMsg },
        'A2UI tool execution failed'
      );
      yield {
        type: EventType.TOOL_CALL_RESULT,
        toolCallId: toolCall.id,
        messageId: resultMessageId,
        content: `[Tool Error] ${toolCall.name}: ${errorMsg}`,
        role: 'tool',
      } as ToolCallResultEvent;
    }
  }

  private async *emitToolResult(
    toolCall: { id: string; name: string; args: string },
    input: RunAgentInput
  ): AsyncGenerator<BaseEvent> {
    if (
      toolCall.name === A2UI_CONSTANTS.TOOL_NAME &&
      this.a2uiIntegration
    ) {
      yield* this.emitA2UIToolResultAndPayloads(toolCall, input);
    } else if (this.mcpIntegration) {
      yield* this.emitToolResultAndResources(toolCall);
    }
  }

  private async *emitToolResultAndResources(
    toolCall: { id: string; name: string; args: string }
  ): AsyncGenerator<BaseEvent> {
    if (!this.mcpIntegration) return;

    const { executeTool } = this.mcpIntegration;
    const resultMessageId = this.generateMessageId();
    const parsedArgs = parseToolArgs(toolCall.args);

    try {
      const { textContent, uiResources } = await executeTool(toolCall.name, parsedArgs);

      yield {
        type: EventType.TOOL_CALL_RESULT,
        toolCallId: toolCall.id,
        messageId: resultMessageId,
        content: textContent,
        role: 'tool',
      } as ToolCallResultEvent;

      for (const resource of uiResources) {
        logger.debug(
          { resourceUri: resource?.resource?.uri, hasText: !!(resource as any)?.resource?.text, hasBlob: !!(resource as any)?.resource?.blob },
          'Emitting CUSTOM mcp-ui-resource event'
        );
        yield {
          type: EventType.CUSTOM,
          name: CUSTOM_EVENT_NAMES.MCP_UI_RESOURCE,
          value: resource,
        } as BaseEvent;
      }
    } catch (error) {
      const errorMsg = getErrorMessage(error);
      logger.warn(
        { toolCallId: toolCall.id, toolName: toolCall.name, error: errorMsg },
        'MCP tool execution failed'
      );
      yield {
        type: EventType.TOOL_CALL_RESULT,
        toolCallId: toolCall.id,
        messageId: resultMessageId,
        content: `[Tool Error] ${toolCall.name}: ${errorMsg}`,
        role: 'tool',
      } as ToolCallResultEvent;
    }
  }

  private async fetchWithRetry(url: string, options: Parameters<typeof fetch>[1]): Promise<Response> {
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

  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages, tools, context } = input;

    logger.info(
      {
        threadId,
        runId,
        model: this.llmConfig.model,
        messageCount: messages.length,
        toolCount: tools?.length || 0,
      },
      'Running LLM agent'
    );

    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    try {
      const contextSummary = getContextSummaryLines(context);

      if (tools?.length) {
        contextSummary.push(`Available tools: ${tools.map((t) => t.name).join(', ')}`);
        logger.debug(
          { threadId, runId, toolCount: tools.length, toolNames: tools.map((t) => t.name) },
          'Tools available (not passed to LLM in demo mode)'
        );
      }

      const chatMessages = buildChatMessages(messages, contextSummary, undefined);
      logger.debug(
        { threadId, runId, messageCount: chatMessages.length },
        'Converted messages to OpenAI format'
      );

      const allTools: OpenAITool[] = [
        ...(this.mcpIntegration?.tools ?? []),
        ...(this.a2uiIntegration ? [this.a2uiIntegration.tool] : []),
      ];
      const requestBody: Record<string, unknown> = {
        model: this.llmConfig.model,
        messages: chatMessages,
        stream: true,
        temperature: this.llmConfig.temperature ?? 0.7,
      };
      if (allTools.length > 0) {
        requestBody.tools = allTools;
      }

      const toolConversion = tools?.length ? convertTools(tools) : undefined;
      logPrompt(
        threadId,
        runId,
        chatMessages,
        context,
        contextSummary,
        toolConversion
      );

      logger.debug(
        {
          threadId,
          runId,
          endpoint: this.llmConfig.endpoint,
          requestBody: JSON.stringify(requestBody),
          maxRetries: this.maxRetries,
          timeoutMs: this.timeoutMs,
        },
        'Sending request to LLM API'
      );

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

      const messageId = this.generateMessageId();
      let currentToolCall: { id: string; name: string; args: string } | null = null;
      let textMessageStarted = false;

      for await (const chunk of parseSSEStream(response.body!)) {
        if (!chunk.choices?.[0]?.delta) continue;

        const delta = chunk.choices[0].delta;

        if (delta.content) {
          if (!textMessageStarted) {
            yield {
              type: EventType.TEXT_MESSAGE_START,
              messageId,
              role: 'assistant',
            } as TextMessageStartEvent;
            textMessageStarted = true;
          }

          yield {
            type: EventType.TEXT_MESSAGE_CHUNK,
            messageId,
            delta: delta.content,
          } as TextMessageChunkEvent;
        }

        if (delta.tool_calls?.[0]) {
          const toolCall = delta.tool_calls[0];

          if (toolCall.id) {
            if (currentToolCall) {
              yield {
                type: EventType.TOOL_CALL_END,
                toolCallId: currentToolCall.id,
              } as ToolCallEndEvent;
              yield* this.emitToolResult(currentToolCall, input);
            }

            const originalName = toolCall.function?.name || '';
            currentToolCall = {
              id: toolCall.id,
              name: originalName,
              args: '',
            };

            yield {
              type: EventType.TOOL_CALL_START,
              toolCallId: currentToolCall.id,
              toolCallName: currentToolCall.name,
              parentMessageId: messageId,
            } as ToolCallStartEvent;
          }

          if (toolCall.function?.arguments && currentToolCall) {
            currentToolCall.args += toolCall.function.arguments;
            yield {
              type: EventType.TOOL_CALL_ARGS,
              toolCallId: currentToolCall.id,
              delta: toolCall.function.arguments,
            } as ToolCallArgsEvent;
          }
        }
      }

      if (currentToolCall) {
        yield {
          type: EventType.TOOL_CALL_END,
          toolCallId: currentToolCall.id,
        } as ToolCallEndEvent;
        yield* this.emitToolResult(currentToolCall, input);
      }

      if (textMessageStarted) {
        yield {
          type: EventType.TEXT_MESSAGE_END,
          messageId,
        } as TextMessageEndEvent;
      }

      const finished: RunFinishedEvent = {
        type: EventType.RUN_FINISHED,
        threadId,
        runId,
      };
      yield finished;
    } catch (error) {
      const errorDetails: Record<string, unknown> = {
        threadId,
        runId,
        messageCount: messages.length,
        toolCount: tools?.length || 0,
        errorMessage: getErrorMessage(error),
        errorName: error instanceof Error ? error.name : 'UnknownError',
      };

      if (error instanceof Error && error.stack) {
        errorDetails.stack = error.stack;
      }

      if (tools && tools.length > 0) {
        errorDetails.tools = tools.map((t) => ({
          name: t.name,
          description: t.description,
        }));
      }

      logger.error(errorDetails, 'LLM agent error - detailed information');

      yield {
        type: EventType.RUN_ERROR,
        message: getErrorMessage(error),
      } as RunErrorEvent;
    }
  }
}
