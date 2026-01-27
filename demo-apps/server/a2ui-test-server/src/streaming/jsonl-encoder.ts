/**
 * JSONL Encoder for A2UI Protocol
 * Encodes A2UI messages as JSON Lines format for SSE streaming
 */

import type { A2UIMessage } from '../types/a2ui.js';
import { logger } from '../utils/logger.js';

/**
 * JSONL Encoder for A2UI messages
 * Formats messages as Server-Sent Events (SSE) with JSONL content
 */
export class JSONLEncoder {
  /**
   * Encode a single A2UI message to SSE format (JSONL)
   * Format: "data: {json}\n\n"
   */
  encode(message: A2UIMessage): string {
    try {
      const jsonString = JSON.stringify(message);
      return `data: ${jsonString}\n\n`;
    } catch (error) {
      logger.error({ error, message }, 'Failed to encode A2UI message');
      throw error;
    }
  }

  /**
   * Get the appropriate Content-Type header for SSE JSONL
   */
  getContentType(): string {
    return 'text/event-stream; charset=utf-8';
  }

  /**
   * Create SSE comment (for heartbeat or debugging)
   * Format: ": {text}\n\n"
   */
  static comment(text: string): string {
    return `: ${text}\n\n`;
  }

  /**
   * Create SSE retry directive
   * Format: "retry: {ms}\n\n"
   */
  static retry(ms: number): string {
    return `retry: ${ms}\n\n`;
  }

  /**
   * Create SSE event type directive (optional, for debugging)
   * Format: "event: {type}\ndata: {json}\n\n"
   */
  static event(type: string, message: A2UIMessage): string {
    try {
      const jsonString = JSON.stringify(message);
      return `event: ${type}\ndata: ${jsonString}\n\n`;
    } catch (error) {
      logger.error({ error, message }, 'Failed to encode SSE event');
      throw error;
    }
  }
}

/**
 * Async generator wrapper for streaming A2UI messages
 */
export async function* streamA2UIMessages(
  messages: AsyncIterable<A2UIMessage>,
  encoder: JSONLEncoder
): AsyncGenerator<string> {
  for await (const message of messages) {
    yield encoder.encode(message);
  }
}
