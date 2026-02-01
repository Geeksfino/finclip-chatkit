/**
 * Input validation utilities for A2UI requests
 */

import type {
  A2AMessageRequest,
  NormalizedAgentInput,
  ClientEventMessage,
} from '../types/a2ui.js';

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

/**
 * Validate A2A Message request input (A2UI v0.8 compliant)
 */
export function validateA2AMessageRequest(
  input: unknown
): asserts input is A2AMessageRequest {
  if (!input || typeof input !== 'object') {
    throw new ValidationError('Input must be an object');
  }

  const data = input as Record<string, unknown>;
  const message = data.message as Record<string, unknown> | undefined;
  const prompt = message?.prompt as Record<string, unknown> | undefined;
  const text = prompt?.text;

  if (typeof text !== 'string' || !text.trim()) {
    throw new ValidationError('message.prompt.text is required and must be a non-empty string');
  }
}

/**
 * Normalize A2A Message to internal agent input
 */
export function normalizeA2AMessageToAgentInput(
  input: A2AMessageRequest
): NormalizedAgentInput {
  const metadata = input.metadata ?? {};
  return {
    message: input.message.prompt.text,
    surfaceId: metadata.surfaceId ?? 'main',
    metadata: metadata.a2uiClientCapabilities
      ? { a2uiClientCapabilities: metadata.a2uiClientCapabilities }
      : undefined,
    threadId: typeof metadata.threadId === 'string' ? metadata.threadId : undefined,
    runId: typeof metadata.runId === 'string' ? metadata.runId : undefined,
  };
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
