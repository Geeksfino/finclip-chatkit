/**
 * Echo Agent - Simple test agent that echoes back user messages
 */

import { BaseAgent } from './base.js';
import type {
  RunAgentInput,
  BaseEvent,
  RunStartedEvent,
  RunFinishedEvent,
  TextMessageChunkEvent,
} from '@ag-ui/core';
import { EventType } from '@ag-ui/core';
import { getLastUserMessage } from '../utils/helpers.js';

export class EchoAgent extends BaseAgent {
  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages } = input;

    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    const lastUserMessage = getLastUserMessage(messages);
    if (lastUserMessage) {
      const messageId = this.generateMessageId();
      const content = (lastUserMessage as { content?: string }).content ?? '';
      const echoText = `Echo: ${content}`;

      // Stream the echo response
      for (const char of echoText) {
        const chunk: TextMessageChunkEvent = {
          type: EventType.TEXT_MESSAGE_CHUNK,
          messageId,
          delta: char,
        };
        yield chunk;
        await this.delay(50); // Simulate typing
      }
    }

    // Finish run
    const finished: RunFinishedEvent = {
      type: EventType.RUN_FINISHED,
      threadId,
      runId,
    };
    yield finished;
  }
}
