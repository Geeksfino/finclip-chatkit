/**
 * Validation Tests for A2UI
 */

import { describe, it, expect } from 'vitest';
import {
  validateA2UIRequest,
  validateClientEventMessage,
  generateRunId,
  ValidationError,
} from '../src/utils/validation.js';

describe('validateA2UIRequest', () => {
  it('should accept valid input', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'Hello',
    };

    expect(() => validateA2UIRequest(input)).not.toThrow();
  });

  it('should reject missing threadId', () => {
    const input = {
      runId: 'run_123',
      message: 'Hello',
    };

    expect(() => validateA2UIRequest(input)).toThrow(ValidationError);
    expect(() => validateA2UIRequest(input)).toThrow('threadId is required');
  });

  it('should reject missing runId', () => {
    const input = {
      threadId: 'test-thread',
      message: 'Hello',
    };

    expect(() => validateA2UIRequest(input)).toThrow(ValidationError);
    expect(() => validateA2UIRequest(input)).toThrow('runId is required');
  });

  it('should reject missing message', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
    };

    expect(() => validateA2UIRequest(input)).toThrow(ValidationError);
    expect(() => validateA2UIRequest(input)).toThrow('message is required');
  });

  it('should reject non-string message', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 123,
    };

    expect(() => validateA2UIRequest(input)).toThrow(ValidationError);
    expect(() => validateA2UIRequest(input)).toThrow('message is required and must be a string');
  });

  it('should accept optional surfaceId', () => {
    const input = {
      threadId: 'test-thread',
      runId: 'run_123',
      message: 'Hello',
      surfaceId: 'main',
    };

    expect(() => validateA2UIRequest(input)).not.toThrow();
  });
});

describe('validateClientEventMessage', () => {
  it('should accept valid userAction', () => {
    const input = {
      userAction: {
        name: 'click',
        surfaceId: 'main',
        sourceComponentId: 'button-1',
        timestamp: '2025-01-27T10:00:00Z',
        context: {},
      },
    };

    expect(() => validateClientEventMessage(input)).not.toThrow();
  });

  it('should accept valid error', () => {
    const input = {
      error: {
        message: 'Something went wrong',
      },
    };

    expect(() => validateClientEventMessage(input)).not.toThrow();
  });

  it('should reject message without userAction or error', () => {
    const input = {
      something: 'else',
    };

    expect(() => validateClientEventMessage(input)).toThrow(ValidationError);
    expect(() => validateClientEventMessage(input)).toThrow('must contain either userAction or error');
  });

  it('should reject message with both userAction and error', () => {
    const input = {
      userAction: {
        name: 'click',
        surfaceId: 'main',
        sourceComponentId: 'button-1',
        timestamp: '2025-01-27T10:00:00Z',
        context: {},
      },
      error: {
        message: 'Error',
      },
    };

    expect(() => validateClientEventMessage(input)).toThrow(ValidationError);
    expect(() => validateClientEventMessage(input)).toThrow('cannot contain both userAction and error');
  });

  it('should reject userAction without required fields', () => {
    const input = {
      userAction: {
        name: 'click',
        // Missing surfaceId, sourceComponentId, timestamp, context
      },
    };

    expect(() => validateClientEventMessage(input)).toThrow(ValidationError);
  });

  it('should reject error without message', () => {
    const input = {
      error: {},
    };

    expect(() => validateClientEventMessage(input)).toThrow(ValidationError);
    expect(() => validateClientEventMessage(input)).toThrow('error.message is required');
  });
});

describe('generateRunId', () => {
  it('should generate a valid run ID', () => {
    const runId = generateRunId();
    expect(runId).toMatch(/^run_\d+_[A-Z0-9]+$/);
  });

  it('should generate unique run IDs', () => {
    const runId1 = generateRunId();
    const runId2 = generateRunId();
    expect(runId1).not.toBe(runId2);
  });
});
