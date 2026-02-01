/**
 * Shared helper utilities
 */

/**
 * Parse tool call arguments JSON safely
 */
export function parseToolArgs(args: string): Record<string, unknown> {
  try {
    return JSON.parse(args || '{}') as Record<string, unknown>;
  } catch {
    return {};
  }
}

/**
 * Get the last user message from a message array
 */
export function getLastUserMessage<T extends { role: string }>(messages: T[]): T | undefined {
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i].role === 'user') return messages[i];
  }
  return undefined;
}

/**
 * Get last user message text content as string (safe for A2UI/LLM input)
 */
export function getLastUserMessageContent(messages: Array<{ role: string; content?: unknown }>): string {
  const last = getLastUserMessage(messages);
  if (!last || !('content' in last) || typeof last.content !== 'string') return '';
  return last.content;
}

/**
 * Extract error message from unknown error
 */
export function getErrorMessage(error: unknown): string {
  return error instanceof Error ? error.message : 'Unknown error';
}
