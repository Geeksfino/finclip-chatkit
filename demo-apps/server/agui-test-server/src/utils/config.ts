/**
 * Configuration loader
 */

import { config as loadEnv } from 'dotenv';
import type {
  AgentMode,
  ServerConfig,
  LLMConfig,
  ProviderType,
  ExtensionMode,
  MCPConfig,
  A2UIConfig,
} from '../types/agui.js';
import { PROVIDER_DEFAULT_URLS } from '../types/agui.js';

loadEnv();

function parseIntEnv(value: string | undefined, defaultValue: number): number {
  if (!value) return defaultValue;
  const parsed = parseInt(value, 10);
  return isNaN(parsed) ? defaultValue : parsed;
}

function resolveAgentMode(): AgentMode {
  const args = process.argv.slice(2);
  if (args.includes('--use-llm')) return 'llm';
  if (args.includes('--emulated')) return 'emulated';
  const envMode = process.env.AGENT_MODE?.toLowerCase();
  if (envMode === 'llm') return 'llm';
  return 'emulated';
}

function loadLLMConfig(): LLMConfig {
  const provider = (process.env.LLM_PROVIDER || 'deepseek').toLowerCase() as ProviderType;
  const model = process.env.LLM_MODEL || 'deepseek-chat';
  const apiKey = process.env.LLM_API_KEY || '';
  const baseUrl = process.env.LLM_BASE_URL || PROVIDER_DEFAULT_URLS[provider] || '';

  return {
    provider,
    model,
    apiKey,
    baseUrl,
    timeoutMs: parseIntEnv(process.env.LLM_TIMEOUT_MS, 60000),
    maxRetries: parseIntEnv(process.env.LLM_MAX_RETRIES, 2),
    retryDelayMs: parseIntEnv(process.env.LLM_RETRY_DELAY_MS, 1000),
  };
}

function resolveExtensionMode(): ExtensionMode {
  const mode = (process.env.EXTENSION_MODE || 'none').toLowerCase();
  if (mode === 'mcpui' || mode === 'a2ui') return mode;
  return 'none';
}

function loadMCPConfig(): MCPConfig {
  const extensionMode = resolveExtensionMode();
  const mcpuiUrl = process.env.MCPUI_SERVER_URL || 'http://localhost:3100/mcp';

  return {
    enabled: extensionMode === 'mcpui',
    serverUrl: mcpuiUrl,
    serverId: process.env.MCP_SERVER_ID || 'mcpui-test-server',
    connectTimeoutMs: parseIntEnv(process.env.MCP_CONNECT_TIMEOUT_MS, 5000),
    toolCallTimeoutMs: parseIntEnv(process.env.MCP_TOOL_CALL_TIMEOUT_MS, 30000),
  };
}

function loadA2UIConfig(): A2UIConfig {
  const extensionMode = resolveExtensionMode();
  // a2ui-test-server default port is 3200
  const a2uiUrl = process.env.A2UI_SERVER_URL || 'http://localhost:3200';

  return {
    enabled: extensionMode === 'a2ui',
    serverUrl: a2uiUrl,
    timeoutMs: parseIntEnv(process.env.A2UI_TIMEOUT_MS, 60000),
  };
}

export function loadConfig(): ServerConfig {
  const agentMode = resolveAgentMode();
  const defaultScenario = process.env.DEFAULT_SCENARIO || 'tool-call';

  return {
    port: parseIntEnv(process.env.PORT, 3000),
    host: process.env.HOST || '0.0.0.0',
    corsOrigin: process.env.CORS_ORIGIN || '*',
    logLevel: process.env.LOG_LEVEL || 'info',
    logPretty: process.env.LOG_PRETTY === 'true',
    sseRetryMs: parseIntEnv(process.env.SSE_RETRY_MS, 3000),
    sseHeartbeatMs: parseIntEnv(process.env.SSE_HEARTBEAT_MS, 30000),
    agentMode,
    defaultScenario,
    scenarioDir: process.env.SCENARIO_DIR || './src/scenarios',
    scenarioDelayMs: parseIntEnv(process.env.SCENARIO_DELAY_MS, 200),
    llm: loadLLMConfig(),
    extensionMode: resolveExtensionMode(),
    mcp: loadMCPConfig(),
    a2ui: loadA2UIConfig(),
  };
}
