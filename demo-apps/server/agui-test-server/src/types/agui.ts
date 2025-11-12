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
  type: 'scenario' | 'litellm' | 'deepseek' | 'echo';
  scenarioId?: string;
  model?: string;
  temperature?: number;
}

export type AgentMode = 'emulated' | 'llm';

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
  llmProvider: string;
  litellmEndpoint?: string;
  litellmModel?: string;
  litellmApiKey?: string;
  deepseekApiKey?: string;
  deepseekModel?: string;
}
