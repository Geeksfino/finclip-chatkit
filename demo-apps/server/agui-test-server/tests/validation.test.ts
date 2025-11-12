/**
 * Validation Tests
 */

import { describe, it, expect } from 'vitest';
import { validateRunAgentInput, generateRunId, ValidationError } from '../src/utils/validation.js';

describe('validateRunAgentInput', () => {
  it('should accept valid input', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      messages: [],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    expect(() => validateRunAgentInput(input)).not.toThrow();
  });

  it('should reject missing threadId', () => {
    const input = {
      runId: 'run_123',
      messages: [],
    };

    expect(() => validateRunAgentInput(input)).toThrow(ValidationError);
    expect(() => validateRunAgentInput(input)).toThrow('threadId is required');
  });

  it('should reject missing runId', () => {
    const input = {
      threadId: 'test-thread',
      messages: [],
    };

    expect(() => validateRunAgentInput(input)).toThrow(ValidationError);
    expect(() => validateRunAgentInput(input)).toThrow('runId is required');
  });

  it('should reject non-array messages', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      messages: 'not-an-array',
    };

    expect(() => validateRunAgentInput(input)).toThrow(ValidationError);
    expect(() => validateRunAgentInput(input)).toThrow('messages must be an array');
  });

  it('should accept optional tools and context', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      messages: [],
    };

    expect(() => validateRunAgentInput(input)).not.toThrow();
  });
});

describe('generateRunId', () => {
  it('should generate valid run ID format', () => {
    const runId = generateRunId();
    expect(runId).toMatch(/^run_\d+_[A-Z0-9]+$/);
  });

  it('should generate unique IDs', () => {
    const id1 = generateRunId();
    const id2 = generateRunId();
    expect(id1).not.toBe(id2);
  });
});
