/**
 * A2UI Agent - Proxies to a2ui-test-server
 * Yields RUN_STARTED → CUSTOM (a2ui) → RUN_FINISHED (no TEXT_MESSAGE_* / TOOL_CALL_*)
 */

import { BaseAgent } from './base.js';
import type { RunAgentInput, BaseEvent, RunStartedEvent, RunFinishedEvent } from '@ag-ui/core';
import { EventType } from '@ag-ui/core';
import { streamA2UIPayloads } from '../a2ui/index.js';
import { extractA2UIForwardedProps, createA2UICustomEvent } from '../a2ui/utils.js';
import { getLastUserMessageContent, getErrorMessage } from '../utils/helpers.js';
import { logger } from '../utils/logger.js';

export interface A2UIAgentConfig {
  serverUrl: string;
  timeoutMs: number;
}

export class A2UIAgent extends BaseAgent {
  constructor(private config: A2UIAgentConfig) {
    super();
  }

  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages } = input;
    const message = getLastUserMessageContent(messages);

    logger.info(
      { threadId, runId, messageLength: message.length },
      'A2UI agent: proxying to a2ui-test-server'
    );

    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    try {
      const { metadata, surfaceId } = extractA2UIForwardedProps(input.forwardedProps);
      let count = 0;

      for await (const payload of streamA2UIPayloads(
        this.config.serverUrl,
        { threadId, runId, message, surfaceId, metadata },
        this.config.timeoutMs
      )) {
        count++;
        yield createA2UICustomEvent(threadId, payload);
      }

      logger.info(
        { threadId, runId, payloadCount: count },
        'A2UI agent: stream completed'
      );
    } catch (error) {
      const errMsg = getErrorMessage(error);
      logger.error({ threadId, runId, error: errMsg }, 'A2UI agent: proxy failed');
      yield {
        type: EventType.RUN_ERROR,
        message: `A2UI proxy error: ${errMsg}`,
      } as BaseEvent;
      return;
    }

    const finished: RunFinishedEvent = {
      type: EventType.RUN_FINISHED,
      threadId,
      runId,
    };
    yield finished;
  }
}
