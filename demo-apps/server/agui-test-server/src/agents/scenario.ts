/**
 * Scenario Agent - Plays back pre-scripted scenarios
 */

import { BaseAgent } from './base.js';
import type {
  RunAgentInput,
  BaseEvent,
  RunStartedEvent,
  RunFinishedEvent,
  RunErrorEvent,
  TextMessageChunkEvent,
} from '@ag-ui/core';
import { EventType } from '@ag-ui/core';
import type { Scenario, ScenarioTurn } from '../types/scenario.js';
import { logger } from '../utils/logger.js';

export class ScenarioAgent extends BaseAgent {
  constructor(
    private scenario: Scenario,
    private defaultDelayMs: number = 200
  ) {
    super();
  }

  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages } = input;

    logger.info(
      { scenarioId: this.scenario.id, threadId, runId },
      'Running scenario'
    );

    // Start run
    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    try {
      // Find matching turn based on last user message
      const lastUserMessage = messages
        .filter((m) => m.role === 'user')
        .pop();

      const turn = this.findMatchingTurn(lastUserMessage?.content);

      if (turn) {
        // Play back the turn's events
        for (const event of turn.events) {
          // Inject threadId and runId if not present
          const enrichedEvent = this.enrichEvent(event, threadId, runId);
          yield enrichedEvent;

          // Add delay between events
          const delay = turn.delayMs ?? this.defaultDelayMs;
          if (delay > 0) {
            await this.delay(delay);
          }
        }
      } else {
        // No matching turn - send a default response
        const messageId = this.generateMessageId();
        const defaultText = 'No matching scenario turn found.';

        for (const char of defaultText) {
          const chunk: TextMessageChunkEvent = {
            type: EventType.TEXT_MESSAGE_CHUNK,
            messageId,
            delta: char,
          };
          yield chunk;
          await this.delay(50);
        }
      }

      // Finish run
      const finished: RunFinishedEvent = {
        type: EventType.RUN_FINISHED,
        threadId,
        runId,
      };
      yield finished;
    } catch (error) {
      logger.error({ error, scenarioId: this.scenario.id }, 'Scenario error');
      const errEvt: RunErrorEvent = {
        type: EventType.RUN_ERROR,
        message: error instanceof Error ? error.message : 'Unknown error',
      };
      yield errEvt;
    }
  }

  private findMatchingTurn(userMessage?: string): ScenarioTurn | undefined {
    if (!userMessage) {
      return this.scenario.turns[0];
    }

    for (const turn of this.scenario.turns) {
      const pattern = turn.trigger.userMessage;
      if (!pattern) continue;

      if (pattern === '*') {
        return turn;
      }

      try {
        const regex = new RegExp(pattern, 'i');
        if (regex.test(userMessage)) {
          return turn;
        }
      } catch {
        // Invalid regex, try exact match
        if (pattern.toLowerCase() === userMessage.toLowerCase()) {
          return turn;
        }
      }
    }

    return undefined;
  }

  private enrichEvent(
    event: BaseEvent,
    threadId: string,
    runId: string
  ): BaseEvent {
    switch (event.type) {
      case EventType.RUN_STARTED: {
        const e: RunStartedEvent = {
          type: EventType.RUN_STARTED,
          threadId: (event as any).threadId || threadId,
          runId: (event as any).runId || runId,
        };
        return e;
      }
      case EventType.RUN_FINISHED: {
        const e: RunFinishedEvent = {
          type: EventType.RUN_FINISHED,
          threadId: (event as any).threadId || threadId,
          runId: (event as any).runId || runId,
        };
        return e;
      }
      default:
        return event;
    }
  }
}
