/**
 * Agent Tests for A2UI
 */

import { describe, it, expect } from 'vitest';
import { ScenarioAgent } from '../src/agents/scenario.js';
import type { A2UIMessage } from '../src/types/a2ui.js';

describe('ScenarioAgent', () => {
  it('should generate A2UI messages for hello message', async () => {
    const agent = new ScenarioAgent();
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'hello',
    };

    const messages: A2UIMessage[] = [];
    for await (const message of agent.run(input)) {
      messages.push(message);
    }

    // Should have at least surfaceUpdate, dataModelUpdate, and beginRendering
    expect(messages.length).toBeGreaterThanOrEqual(3);

    // Check for surfaceUpdate
    const surfaceUpdate = messages.find(m => 'surfaceUpdate' in m);
    expect(surfaceUpdate).toBeDefined();
    if (surfaceUpdate && 'surfaceUpdate' in surfaceUpdate) {
      expect(surfaceUpdate.surfaceUpdate.surfaceId).toBeDefined();
      expect(surfaceUpdate.surfaceUpdate.components.length).toBeGreaterThan(0);
    }

    // Check for beginRendering
    const beginRendering = messages.find(m => 'beginRendering' in m);
    expect(beginRendering).toBeDefined();
    if (beginRendering && 'beginRendering' in beginRendering) {
      expect(beginRendering.beginRendering.surfaceId).toBeDefined();
      expect(beginRendering.beginRendering.root).toBeDefined();
    }
  });

  it('should generate A2UI messages for form message', async () => {
    const agent = new ScenarioAgent();
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'form',
    };

    const messages: A2UIMessage[] = [];
    for await (const message of agent.run(input)) {
      messages.push(message);
    }

    expect(messages.length).toBeGreaterThanOrEqual(3);

    // Check for form components
    const surfaceUpdate = messages.find(m => 'surfaceUpdate' in m);
    expect(surfaceUpdate).toBeDefined();
    if (surfaceUpdate && 'surfaceUpdate' in surfaceUpdate) {
      const hasTextField = surfaceUpdate.surfaceUpdate.components.some(
        c => c.component && ('TextField' in c.component || 'DateTimeInput' in c.component)
      );
      expect(hasTextField).toBe(true);
    }
  });

  it('should handle default message when no scenario matches', async () => {
    const agent = new ScenarioAgent();
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'xyz123unknown',
    };

    const messages: A2UIMessage[] = [];
    for await (const message of agent.run(input)) {
      messages.push(message);
    }

    // Should still generate default UI
    expect(messages.length).toBeGreaterThanOrEqual(3);
    expect(messages.some(m => 'beginRendering' in m)).toBe(true);
  });

  it('should use provided surfaceId', async () => {
    const agent = new ScenarioAgent();
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'hello',
      surfaceId: 'custom-surface',
    };

    const messages: A2UIMessage[] = [];
    for await (const message of agent.run(input)) {
      messages.push(message);
    }

    const surfaceUpdate = messages.find(m => 'surfaceUpdate' in m);
    expect(surfaceUpdate).toBeDefined();
    if (surfaceUpdate && 'surfaceUpdate' in surfaceUpdate) {
      expect(surfaceUpdate.surfaceUpdate.surfaceId).toBe('custom-surface');
    }
  });
});
