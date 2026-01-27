/**
 * Scenario Agent - Plays back pre-scripted A2UI scenarios
 */

import { BaseAgent } from './base.js';
import type { A2UIRequest, A2UIMessage } from '../types/a2ui.js';
import type { Scenario, ScenarioTurn } from '../types/scenario.js';
import { loadAllScenarios, getDefaultScenarioDir } from '../scenarios/index.js';
import { logger } from '../utils/logger.js';
import { loadConfig } from '../utils/config.js';

const config = loadConfig();

export class ScenarioAgent extends BaseAgent {
  private scenarios: Map<string, Scenario>;

  constructor(
    scenarioDir?: string,
    private defaultDelayMs: number = config.scenarioDelayMs
  ) {
    super();
    const dir = scenarioDir || getDefaultScenarioDir();
    this.scenarios = loadAllScenarios(dir);
  }

  async *run(input: A2UIRequest): AsyncGenerator<A2UIMessage> {
    const { threadId, runId, message, surfaceId } = input;

    logger.info(
      { threadId, runId, messageLength: message.length, scenarioCount: this.scenarios.size },
      'Running scenario agent'
    );

    // Find matching scenario and turn
    const turn = this.findMatchingTurn(message);

    if (turn) {
      const targetSurfaceId = surfaceId || 'main';
      
      // Play back the turn's messages
      for (const msg of turn.messages) {
        // Inject surfaceId if not present
        const enrichedMessage = this.enrichMessage(msg, targetSurfaceId);
        yield enrichedMessage;

        // Add delay between messages for streaming effect
        const delay = turn.delayMs ?? this.defaultDelayMs;
        if (delay > 0) {
          await this.delay(delay);
        }
      }
    } else {
      // No matching turn - send a default response
      const defaultSurfaceId = surfaceId || 'main';
      
      yield {
        surfaceUpdate: {
          surfaceId: defaultSurfaceId,
          components: [
            {
              id: 'root',
              component: {
                Column: {
                  children: {
                    explicitList: ['default-text'],
                  },
                },
              },
            },
            {
              id: 'default-text',
              component: {
                Text: {
                  text: {
                    literalString: 'No matching scenario found. Try: "hello", "form", "counter", or "list"',
                  },
                },
              },
            },
          ],
        },
      };

      yield {
        dataModelUpdate: {
          surfaceId: defaultSurfaceId,
          contents: [],
        },
      };

      yield {
        beginRendering: {
          surfaceId: defaultSurfaceId,
          root: 'root',
        },
      };
    }
  }

  /**
   * Find matching turn based on user message
   */
  private findMatchingTurn(userMessage?: string): ScenarioTurn | undefined {
    if (!userMessage) {
      // Return first turn from first scenario
      const firstScenario = Array.from(this.scenarios.values())[0];
      return firstScenario?.turns[0];
    }

    // Search through all scenarios
    for (const scenario of this.scenarios.values()) {
      for (const turn of scenario.turns) {
        const pattern = turn.trigger.userMessage;
        if (!pattern) continue;

        if (pattern === '*') {
          return turn;
        }

        try {
          const regex = new RegExp(pattern, 'i');
          if (regex.test(userMessage)) {
            logger.debug({ scenarioId: scenario.id, pattern }, 'Matched scenario turn');
            return turn;
          }
        } catch {
          // Invalid regex, try exact match
          if (pattern.toLowerCase() === userMessage.toLowerCase()) {
            return turn;
          }
        }
      }
    }

    return undefined;
  }

  /**
   * Enrich message with surfaceId if needed
   * Always uses the provided surfaceId, overriding any existing surfaceId in the message
   */
  private enrichMessage(
    message: A2UIMessage,
    surfaceId: string
  ): A2UIMessage {
    if ('surfaceUpdate' in message) {
      return {
        surfaceUpdate: {
          ...message.surfaceUpdate,
          surfaceId: surfaceId, // Always use provided surfaceId
        },
      };
    }

    if ('dataModelUpdate' in message) {
      return {
        dataModelUpdate: {
          ...message.dataModelUpdate,
          surfaceId: surfaceId, // Always use provided surfaceId
        },
      };
    }

    if ('beginRendering' in message) {
      return {
        beginRendering: {
          ...message.beginRendering,
          surfaceId: surfaceId, // Always use provided surfaceId
        },
      };
    }

    if ('deleteSurface' in message) {
      return {
        deleteSurface: {
          ...message.deleteSurface,
          surfaceId: surfaceId, // Always use provided surfaceId
        },
      };
    }

    return message;
  }

  /**
   * Get list of available scenarios
   */
  getAvailableScenarios(): Scenario[] {
    return Array.from(this.scenarios.values());
  }
}
