/**
 * Agent Factory - Creates appropriate agent based on configuration
 */

import type { AGUIAgent } from '../agents/base.js';
import { EchoAgent } from '../agents/echo.js';
import { ScenarioAgent } from '../agents/scenario.js';
import { LLMAgent } from '../agents/llm.js';
import { getScenario } from '../scenarios/index.js';
import type { ServerConfig } from '../types/agui.js';
import type { RunAgentInput } from '@ag-ui/core';
import { logger } from '../utils/logger.js';

export async function createAgent(
  config: ServerConfig,
  input: RunAgentInput
): Promise<AGUIAgent> {
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
      llmProvider: config.llmProvider,
    },
    'Creating agent'
  );

  const useLiteLLM = (providerOverride?: string) => {
    if (!config.litellmEndpoint || !config.litellmApiKey) {
      throw new Error('LiteLLM configuration missing');
    }

    return new LLMAgent({
      endpoint: config.litellmEndpoint,
      apiKey: config.litellmApiKey,
      model: providerOverride || config.litellmModel || 'deepseek-chat',
      maxRetries: 2,
      retryDelayMs: 1000,
      timeoutMs: 30000,
    });
  };

  const useDeepseek = () => {
    if (!config.deepseekApiKey) {
      throw new Error('DeepSeek API key missing');
    }

    return new LLMAgent({
      endpoint: 'https://api.deepseek.com/v1',
      apiKey: config.deepseekApiKey,
      model: config.deepseekModel || 'deepseek-chat',
      maxRetries: 2,
      retryDelayMs: 1000,
      timeoutMs: 30000,
    });
  };

  if (config.agentMode === 'llm') {
    if (config.llmProvider === 'litellm') {
      return useLiteLLM();
    }

    if (config.llmProvider === 'deepseek') {
      return useDeepseek();
    }

    throw new Error(`Unsupported LLM provider: ${config.llmProvider}`);
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
