/**
 * MCP Client Types
 */

export interface MCPClientConfig {
  url: string;
  headers?: Record<string, string>;
  timeout?: number;
}

export interface MCPTool {
  name: string;
  /** Human-readable name for intent matching (e.g. "VIP客户开户表单"). When present, agui includes it in the tool description sent to the LLM. */
  title?: string;
  description?: string;
  inputSchema?: Record<string, unknown>;
}

export interface MCPToolCallResult {
  content?: Array<{
    type: 'text' | 'resource';
    text?: string;
    resource?: {
      uri: string;
      mimeType?: string;
      [key: string]: unknown;
    };
    [key: string]: unknown;
  }>;
  isError?: boolean;
  _meta?: Record<string, unknown>;
}

export interface OpenAITool {
  type: 'function';
  function: {
    name: string;
    description?: string;
    parameters?: Record<string, unknown>;
  };
}
