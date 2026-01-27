/**
 * Agent Factory - Creates agents based on configuration
 */

import { ScenarioAgent } from '../agents/scenario.js';
import { LLMAgent } from '../agents/llm.js';
import type { BaseAgent } from '../agents/base.js';
import { loadConfig } from '../utils/config.js';
import { logger } from '../utils/logger.js';
import { getDefaultScenarioDir } from '../scenarios/index.js';

const config = loadConfig();

/**
 * Create an agent based on configuration
 */
export function createAgent(): BaseAgent {
  if (config.agentMode === 'llm') {
    return createLLMAgent();
  } else {
    return createScenarioAgent();
  }
}

/**
 * Create scenario agent
 */
function createScenarioAgent(): ScenarioAgent {
  const scenarioDir = config.scenarioDir || getDefaultScenarioDir();
  logger.info({ scenarioDir }, 'Creating scenario agent');
  return new ScenarioAgent(scenarioDir, config.scenarioDelayMs);
}

/**
 * Create LLM agent
 */
function createLLMAgent(): LLMAgent {
  if (config.llmProvider === 'gemini') {
    if (!config.geminiApiKey) {
      throw new Error('GEMINI_API_KEY is required for LLM mode with Gemini provider');
    }

    // Note: Gemini API uses different format, for now we'll use a proxy or OpenAI-compatible endpoint
    // In production, you might want to use a service like LiteLLM that provides OpenAI-compatible interface
    logger.warn('Gemini direct API not fully implemented, using OpenAI-compatible endpoint');
    logger.info({ model: 'gemini' }, 'Creating Gemini LLM agent (via OpenAI-compatible endpoint)');
    // For now, use a proxy or fallback to DeepSeek format
    // You can configure a LiteLLM proxy or similar service
    return new LLMAgent({
      endpoint: 'https://api.deepseek.com/v1', // Placeholder - use LiteLLM proxy in production
      apiKey: config.geminiApiKey,
      model: 'gemini-pro',
      temperature: 0.7,
    });
  } else {
    // DeepSeek
    if (!config.deepseekApiKey) {
      throw new Error('DEEPSEEK_API_KEY is required for LLM mode with DeepSeek provider');
    }

    logger.info({ model: config.deepseekModel }, 'Creating DeepSeek LLM agent');
    return new LLMAgent({
      endpoint: 'https://api.deepseek.com/v1',
      apiKey: config.deepseekApiKey,
      model: config.deepseekModel,
      temperature: 0.7,
    });
  }
}
