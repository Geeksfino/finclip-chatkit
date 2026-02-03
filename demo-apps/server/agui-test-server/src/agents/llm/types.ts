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
  `You are a helpful assistant with access to specialized tools.

IMPORTANT - Tool Calling Rules:
1. When the user says "show", "display", "demonstrate", or similar action words followed by a feature name (e.g., "show html", "show form", "show render data", "show api docs"), you MUST call the appropriate tool immediately. Do NOT just describe what you will do - actually invoke the tool.
2. If the user's request matches any available tool functionality, always prefer calling the tool over giving a text-only response.
3. Only respond with plain text for: simple greetings, general questions unrelated to available tools, or conversational responses.
4. When in doubt about whether to use a tool, use the tool.`;
