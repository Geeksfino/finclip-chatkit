/**
 * Agent Factory - Creates appropriate agent based on configuration
 */

import type { AGUIAgent } from '../agents/base.js';
import { EchoAgent } from '../agents/echo.js';
import { ScenarioAgent } from '../agents/scenario.js';
import { LLMAgent, type MCPIntegration, type A2UIIntegration, GENERATE_A2UI_TOOL } from '../agents/llm.js';
import { A2UIAgent } from '../agents/a2ui.js';
import { getScenario } from '../scenarios/index.js';
import type { ServerConfig, LLMConfig, ProviderType } from '../types/agui.js';
import { PROVIDER_DEFAULT_URLS } from '../types/agui.js';
import type { RunAgentInput } from '@ag-ui/core';
import { logger } from '../utils/logger.js';
import { mcpClientManager } from '../mcp/index.js';

const SUPPORTED_PROVIDERS: ProviderType[] = ['openai', 'deepseek', 'siliconflow', 'litellm'];

function createLLMAgent(
  llmConfig: LLMConfig,
  serverConfig: ServerConfig
): LLMAgent {
  const { provider, model, apiKey, baseUrl, timeoutMs, maxRetries, retryDelayMs } = llmConfig;

  if (!SUPPORTED_PROVIDERS.includes(provider)) {
    throw new Error(
      `Unsupported LLM provider: ${provider}. Supported providers: ${SUPPORTED_PROVIDERS.join(', ')}`
    );
  }

  if (!apiKey) {
    throw new Error(
      `LLM_API_KEY is required for provider "${provider}". Please set it in your .env file.`
    );
  }

  const endpoint = baseUrl || PROVIDER_DEFAULT_URLS[provider];
  if (!endpoint) {
    throw new Error(
      `No endpoint configured for provider "${provider}". Please set LLM_BASE_URL in your .env file.`
    );
  }

  let mcpIntegration: MCPIntegration | undefined;
  if (
    serverConfig.extensionMode === 'mcpui' &&
    serverConfig.mcp.enabled &&
    mcpClientManager.isConnected(serverConfig.mcp.serverId)
  ) {
    const tools = mcpClientManager.getToolsAsOpenAIFormat(serverConfig.mcp.serverId);
    mcpIntegration = {
      serverId: serverConfig.mcp.serverId,
      tools,
      toolCallTimeoutMs: serverConfig.mcp.toolCallTimeoutMs,
      executeTool: async (toolName, args) => {
        const timeoutMs = serverConfig.mcp.toolCallTimeoutMs;
        const mcpResult = await Promise.race([
          mcpClientManager.callTool(serverConfig.mcp.serverId, toolName, args),
          new Promise<never>((_, reject) =>
            setTimeout(() => reject(new Error(`MCP tool timeout after ${timeoutMs}ms`)), timeoutMs)
          ),
        ]);
        const textContent =
          mcpResult.content
            ?.filter((c) => c.type === 'text')
            .map((c) => c.text)
            .join('\n') || 'Tool executed successfully';
        const uiResources = mcpResult.content?.filter((c) => c.type === 'resource') || [];
        return { textContent, uiResources };
      },
    };
    logger.info(
      { serverId: serverConfig.mcp.serverId, toolCount: tools.length },
      'LLM agent created with MCPUI integration'
    );
  }

  let a2uiIntegration: A2UIIntegration | undefined;
  if (
    serverConfig.extensionMode === 'a2ui' &&
    serverConfig.a2ui.enabled &&
    serverConfig.agentMode === 'llm'
  ) {
    a2uiIntegration = {
      serverUrl: serverConfig.a2ui.serverUrl,
      timeoutMs: serverConfig.a2ui.timeoutMs,
      tool: GENERATE_A2UI_TOOL,
    };
    logger.info(
      { serverUrl: serverConfig.a2ui.serverUrl },
      'LLM agent created with A2UI integration (intent-driven)'
    );
  }

  return new LLMAgent(
    {
      endpoint,
      apiKey,
      model,
      maxRetries,
      retryDelayMs,
      timeoutMs,
    },
    mcpIntegration,
    a2uiIntegration
  );
}

export async function createAgent(
  config: ServerConfig,
  input: RunAgentInput
): Promise<AGUIAgent> {
  // A2UI mode (emulated only): always proxy to a2ui-test-server. For llm, use LLMAgent with A2UI tool (intent-driven).
  if (
    config.extensionMode === 'a2ui' &&
    config.a2ui.enabled &&
    config.agentMode !== 'llm'
  ) {
    logger.info(
      { serverUrl: config.a2ui.serverUrl },
      'Creating A2UI agent (proxy to a2ui-test-server, emulated mode)'
    );
    return new A2UIAgent({
      serverUrl: config.a2ui.serverUrl,
      timeoutMs: config.a2ui.timeoutMs,
    });
  }

  const scenarioOverride =
    config.agentMode === 'emulated'
      ? ((input.forwardedProps as any)?.scenarioId as string | undefined)
      : undefined;
  const effectiveScenario = scenarioOverride ?? config.defaultScenario;

  logger.debug(
    {
      agentMode: config.agentMode,
      scenarioOverride,
      effectiveScenario,
      llmProvider: config.llm.provider,
      llmModel: config.llm.model,
    },
    'Creating agent'
  );

  if (config.agentMode === 'llm') {
    return createLLMAgent(config.llm, config);
  }

  // Emulated (scenario) mode
  if (effectiveScenario === 'echo') {
    return new EchoAgent();
  }

  const scenario = getScenario(effectiveScenario);
  if (!scenario) {
    throw new Error(`Scenario not found: ${effectiveScenario}`);
  }

  return new ScenarioAgent(scenario, config.scenarioDelayMs);
}
