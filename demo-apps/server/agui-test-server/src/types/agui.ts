/**
 * AG-UI Protocol Types
 * Re-exports from @ag-ui/core with additional server-specific types
 */
import type { Message } from '@ag-ui/core';
export type {
  RunAgentInput,
  Tool,
  Context,
  BaseEvent,
  RunStartedEvent,
  RunFinishedEvent,
  RunErrorEvent,
  TextMessageChunkEvent,
  ToolCallStartEvent,
  ToolCallArgsEvent,
  ToolCallEndEvent,
  MessagesSnapshotEvent,
} from '@ag-ui/core';

export { EventType } from '@ag-ui/core';

/**
 * Server-specific types
 */

export interface SessionState {
  threadId: string;
  messages: Message[];
  createdAt: Date;
  lastActivity: Date;
}

export interface AgentConfig {
  type: 'scenario' | 'llm' | 'echo';
  scenarioId?: string;
  model?: string;
  temperature?: number;
}

export type AgentMode = 'emulated' | 'llm';

/**
 * LLM Provider Configuration (aligned with knowledgebase project)
 */

/** Supported provider types */
export type ProviderType = 'openai' | 'deepseek' | 'siliconflow' | 'litellm';

/** Default base URLs per provider */
export const PROVIDER_DEFAULT_URLS: Record<ProviderType, string> = {
  openai: 'https://api.openai.com/v1',
  deepseek: 'https://api.deepseek.com/v1',
  siliconflow: 'https://api.siliconflow.cn/v1',
  litellm: 'http://localhost:4000/v1',
};

/** LLM configuration interface */
export interface LLMConfig {
  provider: ProviderType;
  model: string;
  apiKey: string;
  baseUrl: string;
  timeoutMs: number;
  maxRetries: number;
  retryDelayMs: number;
}

export type ExtensionMode = 'none' | 'mcpui' | 'a2ui';

export interface MCPConfig {
  enabled: boolean;
  serverUrl: string;
  serverId: string;
  connectTimeoutMs: number;
  toolCallTimeoutMs: number;
}

export interface A2UIConfig {
  enabled: boolean;
  serverUrl: string;
  timeoutMs: number;
}

/** A2UIPayloadWire - maps a2ui-test-server message to AG-UI CUSTOM value */
export interface A2UIPayloadWire {
  type: 'beginRendering' | 'surfaceUpdate' | 'dataModelUpdate' | 'deleteSurface';
  payload: Record<string, unknown>;
}

export interface ServerConfig {
  port: number;
  host: string;
  corsOrigin: string;
  logLevel: string;
  logPretty: boolean;
  sseRetryMs: number;
  sseHeartbeatMs: number;
  agentMode: AgentMode;
  defaultScenario: string;
  scenarioDir: string;
  scenarioDelayMs: number;
  llm: LLMConfig;
  extensionMode: ExtensionMode;
  mcp: MCPConfig;
  a2ui: A2UIConfig;
}
