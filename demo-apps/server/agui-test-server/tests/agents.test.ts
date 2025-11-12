/**
 * Agent Tests
 */

import { describe, it, expect } from 'vitest';
import { EchoAgent } from '../src/agents/echo.js';
import { EventType } from '@ag-ui/core';
import type {
  RunAgentInput,
  BaseEvent,
  TextMessageChunkEvent,
} from '@ag-ui/core';

describe('EchoAgent', () => {
  it('should echo user message', async () => {
    const agent = new EchoAgent();
    const input: RunAgentInput = {
      threadId: 'test-thread',
      runId: 'run_123',
      messages: [
        {
          id: 'msg-1',
          role: 'user',
          content: 'Hello',
        },
      ],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: BaseEvent[] = [];
    for await (const event of agent.run(input)) {
      events.push(event);
    }

    // Should have RUN_STARTED, TEXT_MESSAGE_CHUNK(s), RUN_FINISHED
    expect(events.length).toBeGreaterThanOrEqual(2);
    expect(events[0]?.type).toBe(EventType.RUN_STARTED);
    expect(events[events.length - 1]?.type).toBe(EventType.RUN_FINISHED);

    // Should contain echo text
    const textChunks = events.filter(
      (e): e is TextMessageChunkEvent => e.type === EventType.TEXT_MESSAGE_CHUNK
    );
    expect(textChunks.length).toBeGreaterThan(0);

    const fullText = textChunks.map(e => e.delta ?? '').join('');
    expect(fullText).toContain('Echo: Hello');
  });

  it('should handle empty messages', async () => {
    const agent = new EchoAgent();
    const input: RunAgentInput = {
      threadId: 'test-thread',
      runId: 'run_123',
      messages: [],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: BaseEvent[] = [];
    for await (const event of agent.run(input)) {
      events.push(event);
    }

    // Should still have lifecycle events
    expect(events.length).toBeGreaterThanOrEqual(2);
    expect(events[0]?.type).toBe(EventType.RUN_STARTED);
    expect(events[events.length - 1]?.type).toBe(EventType.RUN_FINISHED);
  });
});
