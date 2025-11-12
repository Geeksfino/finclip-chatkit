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

export class EchoAgent extends BaseAgent {
  async *run(input: RunAgentInput): AsyncGenerator<BaseEvent> {
    const { threadId, runId, messages } = input;

    // Start run
    const started: RunStartedEvent = {
      type: EventType.RUN_STARTED,
      threadId,
      runId,
    };
    yield started;

    // Get last user message
    const lastUserMessage = messages
      .filter((m) => m.role === 'user')
      .pop();

    if (lastUserMessage) {
      const messageId = this.generateMessageId();
      const echoText = `Echo: ${lastUserMessage.content}`;

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
