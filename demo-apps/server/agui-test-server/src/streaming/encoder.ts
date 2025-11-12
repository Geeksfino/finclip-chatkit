/**
 * SSE Event Encoder
 * Wraps @ag-ui/encoder with server-specific utilities
 */

import { EventEncoder } from '@ag-ui/encoder';
import type { BaseEvent } from '@ag-ui/core';
import { logger } from '../utils/logger.js';

export class SSEEncoder {
  private encoder: EventEncoder;

  constructor(acceptHeader?: string) {
    this.encoder = new EventEncoder({ accept: acceptHeader });
  }

  /**
   * Encode a single AG-UI event to SSE format
   */
  encode(event: BaseEvent): string {
    try {
      return this.encoder.encode(event);
    } catch (error) {
      logger.error({ error, event }, 'Failed to encode event');
      throw error;
    }
  }

  /**
   * Get the appropriate Content-Type header
   */
  getContentType(): string {
    return this.encoder.getContentType();
  }

  /**
   * Create SSE comment (for heartbeat)
   */
  static comment(text: string): string {
    return `: ${text}\n\n`;
  }

  /**
   * Create SSE retry directive
   */
  static retry(ms: number): string {
    return `retry: ${ms}\n\n`;
  }
}

/**
 * Async generator wrapper for streaming events
 */
export async function* streamEvents(
  events: AsyncIterable<BaseEvent>,
  encoder: SSEEncoder
): AsyncGenerator<string> {
  for await (const event of events) {
    yield encoder.encode(event);
  }
}
