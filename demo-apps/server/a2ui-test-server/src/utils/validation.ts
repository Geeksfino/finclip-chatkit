/**
 * Input validation utilities for A2UI requests
 */

import type { A2UIRequest, ClientEventMessage } from '../types/a2ui.js';

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

/**
 * Validate A2UI request input
 */
export function validateA2UIRequest(input: unknown): asserts input is A2UIRequest {
  if (!input || typeof input !== 'object') {
    throw new ValidationError('Input must be an object');
  }

  const data = input as Partial<A2UIRequest>;

  if (!data.threadId || typeof data.threadId !== 'string') {
    throw new ValidationError('threadId is required and must be a string');
  }

  if (!data.runId || typeof data.runId !== 'string') {
    throw new ValidationError('runId is required and must be a string');
  }

  if (!data.message || typeof data.message !== 'string') {
    throw new ValidationError('message is required and must be a string');
  }
}

/**
 * Validate client event message
 */
export function validateClientEventMessage(
  input: unknown
): asserts input is ClientEventMessage {
  if (!input || typeof input !== 'object') {
    throw new ValidationError('Input must be an object');
  }

  const data = input as Record<string, unknown>;

  // Must contain exactly one of userAction or error
  const hasUserAction = 'userAction' in data;
  const hasError = 'error' in data;

  if (!hasUserAction && !hasError) {
    throw new ValidationError('Message must contain either userAction or error');
  }

  if (hasUserAction && hasError) {
    throw new ValidationError('Message cannot contain both userAction and error');
  }

  if (hasUserAction) {
    const userAction = data.userAction as Record<string, unknown>;
    if (!userAction.name || typeof userAction.name !== 'string') {
      throw new ValidationError('userAction.name is required and must be a string');
    }
    if (!userAction.surfaceId || typeof userAction.surfaceId !== 'string') {
      throw new ValidationError('userAction.surfaceId is required and must be a string');
    }
    if (!userAction.sourceComponentId || typeof userAction.sourceComponentId !== 'string') {
      throw new ValidationError('userAction.sourceComponentId is required and must be a string');
    }
    if (!userAction.timestamp || typeof userAction.timestamp !== 'string') {
      throw new ValidationError('userAction.timestamp is required and must be a string');
    }
    if (!userAction.context || typeof userAction.context !== 'object') {
      throw new ValidationError('userAction.context is required and must be an object');
    }
  }

  if (hasError) {
    const error = data.error as Record<string, unknown>;
    if (!error.message || typeof error.message !== 'string') {
      throw new ValidationError('error.message is required and must be a string');
    }
  }
}

/**
 * Generate a run ID
 */
export function generateRunId(): string {
  const timestamp = Math.floor(Date.now() / 1000);
  const random = Math.random().toString(36).substring(2, 10).toUpperCase();
  return `run_${timestamp}_${random}`;
}
