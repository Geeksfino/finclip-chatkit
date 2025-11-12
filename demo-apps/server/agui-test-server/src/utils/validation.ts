/**
 * Input validation utilities
 */

import type { RunAgentInput } from '@ag-ui/core';

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export function validateRunAgentInput(input: unknown): asserts input is RunAgentInput {
  if (!input || typeof input !== 'object') {
    throw new ValidationError('Input must be an object');
  }

  const data = input as Partial<RunAgentInput>;

  if (!data.threadId || typeof data.threadId !== 'string') {
    throw new ValidationError('threadId is required and must be a string');
  }

  if (!data.runId || typeof data.runId !== 'string') {
    throw new ValidationError('runId is required and must be a string');
  }

  if (!Array.isArray(data.messages)) {
    throw new ValidationError('messages must be an array');
  }

  if (data.tools && !Array.isArray(data.tools)) {
    throw new ValidationError('tools must be an array');
  }

  if (data.context && !Array.isArray(data.context)) {
    throw new ValidationError('context must be an array');
  }
}

export function generateRunId(): string {
  const timestamp = Math.floor(Date.now() / 1000);
  const random = Math.random().toString(36).substring(2, 10).toUpperCase();
  return `run_${timestamp}_${random}`;
}
