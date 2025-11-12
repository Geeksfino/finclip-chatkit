/**
 * Configuration loader
 */

import { config as loadEnv } from 'dotenv';
import type { AgentMode, ServerConfig } from '../types/agui.js';

loadEnv();

function resolveAgentMode(): AgentMode {
  const args = process.argv.slice(2);

  if (args.includes('--use-llm')) {
    return 'llm';
  }

  if (args.includes('--emulated')) {
    return 'emulated';
  }

  const envMode = process.env.AGENT_MODE?.toLowerCase();
  if (envMode === 'llm') {
    return 'llm';
  }

  return 'emulated';
}

export function loadConfig(): ServerConfig {
  const agentMode = resolveAgentMode();
  const defaultScenario = process.env.DEFAULT_SCENARIO || 'tool-call';

  return {
    port: parseInt(process.env.PORT || '3000', 10),
    host: process.env.HOST || '0.0.0.0',
    corsOrigin: process.env.CORS_ORIGIN || '*',
    logLevel: process.env.LOG_LEVEL || 'info',
    logPretty: process.env.LOG_PRETTY === 'true',
    sseRetryMs: parseInt(process.env.SSE_RETRY_MS || '3000', 10),
    sseHeartbeatMs: parseInt(process.env.SSE_HEARTBEAT_MS || '30000', 10),
    agentMode,
    defaultScenario,
    scenarioDir: process.env.SCENARIO_DIR || './src/scenarios',
    scenarioDelayMs: parseInt(process.env.SCENARIO_DELAY_MS || '200', 10),
    llmProvider: process.env.LLM_PROVIDER || 'litellm',
    litellmEndpoint: process.env.LITELLM_ENDPOINT,
    litellmModel: process.env.LITELLM_MODEL || 'deepseek-chat',
    litellmApiKey: process.env.LITELLM_API_KEY,
    deepseekApiKey: process.env.DEEPSEEK_API_KEY,
    deepseekModel: process.env.DEEPSEEK_MODEL || 'deepseek-chat',
  };
}
