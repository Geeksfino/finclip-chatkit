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
1. Tool names in the list may be opaque IDs (e.g. scn_xxx). Users refer to tools by their human-readable name or purpose (e.g. "VIP客户开户表单", "开户表单"). Match the user's intent to the tool whose description or title contains that name or meaning, then call that tool using its exact "name" field. Do NOT reply with text only when the user clearly asks to open/show/use a specific page or form—invoke the corresponding tool.
2. When the user says "打开xxx", "显示xxx", "调用工具", "show", "display", "demonstrate", or similar, find the best-matching tool by description/title and call it by name. Prefer calling the tool over giving a text-only response.
3. Only respond with plain text for: simple greetings, general questions unrelated to available tools, or conversational responses.
4. When in doubt about whether to use a tool, use the tool.`;
