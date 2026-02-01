/**
 * Message conversion and context utilities for LLM agent
 */

import type { Message, AssistantMessage, ToolMessage } from '@ag-ui/core';
import type { RunAgentInput } from '@ag-ui/core';
import { getErrorMessage } from '../../utils/helpers.js';
import { logger } from '../../utils/logger.js';
import type { ChatMessage, ToolConversionResult } from './types.js';
import { SYSTEM_PROMPT } from './types.js';
const PREVIEW_LIMIT = 200;

export function convertMessages(
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
        'content' in msg && typeof (msg as { content?: unknown }).content === 'string'
          ? ((msg as { content: string }).content as string)
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
          error: getErrorMessage(error),
        },
        'Error converting message to OpenAI format'
      );
      throw error;
    }
  });
}

export function buildChatMessages(
  messages: Message[],
  _contextSummary: string[],
  nameMap?: Map<string, string>
): ChatMessage[] {
  const sequence: ChatMessage[] = [
    { role: 'system', content: SYSTEM_PROMPT },
  ];
  const converted = convertMessages(messages, nameMap);
  sequence.push(...converted);
  return sequence;
}

export function getContextSummaryLines(context: RunAgentInput['context']): string[] {
  if (!context || context.length === 0) return [];

  const lines: string[] = [];

  for (const entry of context as Array<{ key?: string; value?: { description?: string; data?: unknown } }>) {
    const key = entry?.key ?? 'unknown';
    const description =
      typeof entry?.value?.description === 'string' ? entry.value.description : undefined;

    if (description && description.length > 0) {
      lines.push(description);
      continue;
    }

    if (entry?.value?.data !== undefined) {
      try {
        const serialized = JSON.stringify(entry.value.data);
        const trimmed =
          serialized.length > PREVIEW_LIMIT ? `${serialized.slice(0, PREVIEW_LIMIT)}…` : serialized;
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

export function logPrompt(
  threadId: string,
  runId: string,
  messages: ChatMessage[],
  context: RunAgentInput['context'],
  contextSummary: string[],
  toolConversion?: ToolConversionResult
): void {
  const sanitizedMap = toolConversion?.sanitizedToOriginal;

  const logMessages = messages.map((message) => {
    const content = message.content ?? '';
    const formatted: Record<string, unknown> = {
      role: message.role,
      content: content.length > PREVIEW_LIMIT ? `${content.slice(0, PREVIEW_LIMIT)}…` : content,
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

  const contextLog = (context as Array<{ key?: string; value?: { description?: string; data?: unknown } }> | undefined)?.map((ctx) => {
    const description =
      typeof ctx?.value?.description === 'string' ? ctx.value.description : undefined;
    const data = ctx?.value?.data;
    let dataPreview: string | undefined;
    if (data !== undefined) {
      try {
        const serialized = JSON.stringify(data);
        dataPreview =
          serialized.length > PREVIEW_LIMIT ? `${serialized.slice(0, PREVIEW_LIMIT)}…` : serialized;
      } catch {
        dataPreview = '[unserializable]';
      }
    }

    return {
      key: ctx?.key,
      hasDescription: Boolean(description),
      description:
        description && description.length > PREVIEW_LIMIT
          ? `${description.slice(0, PREVIEW_LIMIT)}…`
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
