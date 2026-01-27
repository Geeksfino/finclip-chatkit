/**
 * Configuration loader for A2UI test server
 */

import { config as loadEnv } from 'dotenv';

loadEnv();

export type AgentMode = 'scenario' | 'llm';
export type LLMProvider = 'gemini' | 'deepseek';

export interface ServerConfig {
  port: number;
  host: string;
  corsOrigin: string;
  logLevel: string;
  logPretty: boolean;
  sseRetryMs: number;
  sseHeartbeatMs: number;
  agentMode: AgentMode;
  scenarioDir: string;
  scenarioDelayMs: number;
  llmProvider: LLMProvider;
  geminiApiKey?: string;
  deepseekApiKey?: string;
  deepseekModel: string;
}

function resolveAgentMode(): AgentMode {
  const envMode = process.env.DEFAULT_AGENT?.toLowerCase();
  if (envMode === 'llm') {
    return 'llm';
  }
  return 'scenario';
}

export function loadConfig(): ServerConfig {
  const agentMode = resolveAgentMode();
  const llmProvider = (process.env.LLM_PROVIDER?.toLowerCase() || 'gemini') as LLMProvider;

  return {
    port: parseInt(process.env.PORT || '3200', 10),
    host: process.env.HOST || '0.0.0.0',
    corsOrigin: process.env.CORS_ORIGIN || '*',
    logLevel: process.env.LOG_LEVEL || 'info',
    logPretty: process.env.LOG_PRETTY === 'true',
    sseRetryMs: parseInt(process.env.SSE_RETRY_MS || '3000', 10),
    sseHeartbeatMs: parseInt(process.env.SSE_HEARTBEAT_MS || '30000', 10),
    agentMode,
    scenarioDir: process.env.SCENARIO_DIR || './src/scenarios',
    scenarioDelayMs: parseInt(process.env.SCENARIO_DELAY_MS || '200', 10),
    llmProvider,
    geminiApiKey: process.env.GEMINI_API_KEY,
    deepseekApiKey: process.env.DEEPSEEK_API_KEY,
    deepseekModel: process.env.DEEPSEEK_MODEL || 'deepseek-chat',
  };
}
