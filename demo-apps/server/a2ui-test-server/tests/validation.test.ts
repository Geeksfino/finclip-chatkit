/**
 * Validation Tests for A2UI
 */

import { describe, it, expect } from 'vitest';
import {
  validateA2AMessageRequest,
  normalizeA2AMessageToAgentInput,
  validateClientEventMessage,
  generateRunId,
  ValidationError,
} from '../src/utils/validation.js';

describe('validateA2AMessageRequest', () => {
  it('should accept valid A2A Message format', () => {
    const input = {
      message: {
        prompt: {
          text: 'Hello, show me a form',
        },
      },
    };

    expect(() => validateA2AMessageRequest(input)).not.toThrow();
  });

  it('should accept A2A Message with metadata', () => {
    const input = {
      metadata: {
        a2uiClientCapabilities: {
          supportedCatalogIds: ['https://example.com/catalog.json'],
        },
        surfaceId: 'main',
        threadId: 'thread-1',
        runId: 'run-1',
      },
      message: {
        prompt: {
          text: 'form',
        },
      },
    };

    expect(() => validateA2AMessageRequest(input)).not.toThrow();
  });

  it('should reject missing message', () => {
    const input = {};

    expect(() => validateA2AMessageRequest(input)).toThrow(ValidationError);
    expect(() => validateA2AMessageRequest(input)).toThrow('message.prompt.text');
  });

  it('should reject missing message.prompt.text', () => {
    const input = {
      message: {},
    };

    expect(() => validateA2AMessageRequest(input)).toThrow(ValidationError);
  });

  it('should reject empty text', () => {
    const input = {
      message: {
        prompt: {
          text: '   ',
        },
      },
    };

    expect(() => validateA2AMessageRequest(input)).toThrow(ValidationError);
  });

  it('should reject non-string text', () => {
    const input = {
      message: {
        prompt: {
          text: 123,
        },
      },
    };

    expect(() => validateA2AMessageRequest(input)).toThrow(ValidationError);
  });
});

describe('normalizeA2AMessageToAgentInput', () => {
  it('should extract message and default surfaceId', () => {
    const input = {
      message: {
        prompt: {
          text: 'form',
        },
      },
    };

    const result = normalizeA2AMessageToAgentInput(input);
    expect(result.message).toBe('form');
    expect(result.surfaceId).toBe('main');
    expect(result.threadId).toBeUndefined();
    expect(result.runId).toBeUndefined();
  });

  it('should preserve metadata', () => {
    const input = {
      metadata: {
        a2uiClientCapabilities: {
          supportedCatalogIds: ['https://example.com/catalog.json'],
        },
        surfaceId: 'custom-surface',
        threadId: 't-1',
        runId: 'r-1',
      },
      message: {
        prompt: {
          text: 'hello',
        },
      },
    };

    const result = normalizeA2AMessageToAgentInput(input);
    expect(result.message).toBe('hello');
    expect(result.surfaceId).toBe('custom-surface');
    expect(result.metadata?.a2uiClientCapabilities?.supportedCatalogIds).toEqual([
      'https://example.com/catalog.json',
    ]);
    expect(result.threadId).toBe('t-1');
    expect(result.runId).toBe('r-1');
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
