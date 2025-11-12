/**
 * LLM Agent Logging Tests
 * Tests that the LLM agent properly logs errors with detailed information
 * 
 * Note: These tests validate logging behavior by testing against
 * unreachable endpoints. The key is that we get proper error logging,
 * not that the API works.
 */

import { describe, it, expect, vi } from 'vitest';
import { LLMAgent } from '../src/agents/llm.js';
import { EventType } from '@ag-ui/core';
import type { RunAgentInput, BaseEvent } from '@ag-ui/core';
import { logger } from '../src/utils/logger.js';

describe('LLMAgent error logging', () => {
  it('should log detailed error information when error occurs with tools provided', async () => {
    const infoSpy = vi.spyOn(logger, 'info');
    const errorSpy = vi.spyOn(logger, 'error');

    // Use invalid endpoint to trigger an error
    const agent = new LLMAgent({
      endpoint: 'http://invalid-nonexistent-domain-for-testing.local:9999/v1',
      apiKey: 'test-key',
      model: 'test-model',
    });

    const input: RunAgentInput = {
      threadId: 'test-thread-123',
      runId: 'run_test_456',
      messages: [
        {
          id: 'msg-1',
          role: 'user',
          content: 'Take a photo',
        },
      ],
      tools: [
        {
          name: 'camera.capture',
          description: 'Capture a photo',
          parameters: {
            type: 'object',
            properties: {
              mode: { type: 'string' },
            },
          },
        },
        {
          name: 'gallery.open',
          description: 'Open gallery',
          parameters: {
            type: 'object',
            properties: {},
          },
        },
      ],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: BaseEvent[] = [];
    for await (const event of agent.run(input)) {
      events.push(event);
    }

    // Verify RUN_STARTED and RUN_ERROR events are emitted
    expect(events.length).toBeGreaterThanOrEqual(2);
    expect(events[0]?.type).toBe(EventType.RUN_STARTED);
    expect(events[events.length - 1]?.type).toBe(EventType.RUN_ERROR);

    // Verify info logging was called with tool count
    expect(infoSpy).toHaveBeenCalled();
    const runningCall = infoSpy.mock.calls.find((call) =>
      call[1]?.includes('Running LLM agent')
    );
    expect(runningCall).toBeDefined();
    if (runningCall) {
      expect(runningCall[0]).toHaveProperty('threadId', 'test-thread-123');
      expect(runningCall[0]).toHaveProperty('runId', 'run_test_456');
      expect(runningCall[0]).toHaveProperty('messageCount', 1);
      expect(runningCall[0]).toHaveProperty('toolCount', 2);
    }

    // Verify error logging includes detailed information
    expect(errorSpy).toHaveBeenCalled();
    const detailedErrorCall = errorSpy.mock.calls.find(
      (call) => call[1] === 'LLM agent error - detailed information'
    );
    expect(detailedErrorCall).toBeDefined();

    if (detailedErrorCall) {
      const errorDetails = detailedErrorCall[0];
      expect(errorDetails).toHaveProperty('threadId', 'test-thread-123');
      expect(errorDetails).toHaveProperty('runId', 'run_test_456');
      expect(errorDetails).toHaveProperty('messageCount', 1);
      expect(errorDetails).toHaveProperty('toolCount', 2);
      expect(errorDetails).toHaveProperty('errorMessage');
      expect(errorDetails).toHaveProperty('errorName');
      
      // Verify tool details are logged
      expect(errorDetails.tools).toBeDefined();
      expect(errorDetails.tools).toHaveLength(2);
      expect(errorDetails.tools[0]).toHaveProperty('name', 'camera.capture');
      expect(errorDetails.tools[0]).toHaveProperty('description', 'Capture a photo');
      expect(errorDetails.tools[1]).toHaveProperty('name', 'gallery.open');
      expect(errorDetails.tools[1]).toHaveProperty('description', 'Open gallery');
      
      // Verify stack trace is included
      expect(errorDetails).toHaveProperty('stack');
    }

    vi.restoreAllMocks();
  });

  it('should log error information without tools when no tools provided', async () => {
    const infoSpy = vi.spyOn(logger, 'info');
    const errorSpy = vi.spyOn(logger, 'error');

    // Use invalid endpoint to trigger an error
    const agent = new LLMAgent({
      endpoint: 'http://invalid-nonexistent-domain-for-testing.local:9999/v1',
      apiKey: 'test-key',
      model: 'test-model',
    });

    const input: RunAgentInput = {
      threadId: 'test-thread-789',
      runId: 'run_test_999',
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

    // Verify error event is emitted
    expect(events[events.length - 1]?.type).toBe(EventType.RUN_ERROR);

    // Verify info logging shows 0 tools
    const runningCall = infoSpy.mock.calls.find((call) =>
      call[1]?.includes('Running LLM agent')
    );
    expect(runningCall).toBeDefined();
    if (runningCall) {
      expect(runningCall[0]).toHaveProperty('toolCount', 0);
    }

    // Verify error logging includes details but no tools array
    const detailedErrorCall = errorSpy.mock.calls.find(
      (call) => call[1] === 'LLM agent error - detailed information'
    );
    expect(detailedErrorCall).toBeDefined();

    if (detailedErrorCall) {
      const errorDetails = detailedErrorCall[0];
      expect(errorDetails).toHaveProperty('threadId', 'test-thread-789');
      expect(errorDetails).toHaveProperty('runId', 'run_test_999');
      expect(errorDetails).toHaveProperty('toolCount', 0);
      expect(errorDetails).toHaveProperty('errorMessage');
      expect(errorDetails).toHaveProperty('stack');
      
      // Tools should not be included when empty
      expect(errorDetails.tools).toBeUndefined();
    }

    vi.restoreAllMocks();
  });
});
