/**
 * LLM Agent types and interfaces
 */

import type { OpenAITool } from '../../mcp/types.js';

export interface LLMConfig {
  endpoint: string;
  apiKey: string;
  model: string;
  temperature?: number;
  maxRetries?: number;
  retryDelayMs?: number;
  timeoutMs?: number;
}

export interface MCPIntegration {
  serverId: string;
  tools: OpenAITool[];
  toolCallTimeoutMs: number;
  executeTool: (
    toolName: string,
    args: Record<string, unknown>
  ) => Promise<{ textContent: string; uiResources: unknown[] }>;
}

export interface A2UIIntegration {
  serverUrl: string;
  timeoutMs: number;
  tool: OpenAITool;
}

export interface ToolConversionResult {
  tools: OpenAITool[];
  sanitizedToOriginal: Map<string, string>;
  originalToSanitized: Map<string, string>;
}

export interface ChatMessage {
  role: string;
  content: string;
  tool_calls?: Array<{
    id: string;
    type: string;
    function: { name: string; arguments: string };
  }>;
  tool_call_id?: string;
}

export interface ChatCompletionChunk {
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

export const SYSTEM_PROMPT =
  'You are a helpful assistant. When tools are available, call them only when the user explicitly requests the corresponding functionality. Do not invoke tools for simple greetings, general questions, or conversational responses.';
