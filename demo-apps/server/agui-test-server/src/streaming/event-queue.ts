/**
 * Event Queue Management
 * Queues events for sessions without active SSE connections
 */

import type { BaseEvent } from '../types/agui.js';
import { logger } from '../utils/logger.js';

export class EventQueue {
  private queues = new Map<string, BaseEvent[]>();
  private maxQueueSize: number;

  constructor(maxQueueSize: number = 100) {
    this.maxQueueSize = maxQueueSize;
  }

  /**
   * Queue an event for a session
   */
  enqueue(sessionId: string, event: BaseEvent): void {
    let queue = this.queues.get(sessionId);
    if (!queue) {
      queue = [];
      this.queues.set(sessionId, queue);
    }

    // Prevent queue from growing too large
    if (queue.length >= this.maxQueueSize) {
      logger.warn({ sessionId, queueSize: queue.length }, 'Event queue full, dropping oldest event');
      queue.shift();
    }

    queue.push(event);
    logger.debug({ sessionId, queueSize: queue.length }, 'Queued event');
  }

  /**
   * Get and clear all queued events for a session
   */
  dequeueAll(sessionId: string): BaseEvent[] {
    const queue = this.queues.get(sessionId) || [];
    this.queues.delete(sessionId);
    if (queue.length > 0) {
      logger.info({ sessionId, count: queue.length }, 'Dequeued events');
    }
    return queue;
  }

  /**
   * Get queued events without clearing them
   */
  peek(sessionId: string): BaseEvent[] {
    return this.queues.get(sessionId) || [];
  }

  /**
   * Clear queue for a session
   */
  clear(sessionId: string): void {
    this.queues.delete(sessionId);
  }

  /**
   * Get queue size for a session
   */
  size(sessionId: string): number {
    return this.queues.get(sessionId)?.length || 0;
  }

  /**
   * Clear all queues
   */
  clearAll(): void {
    this.queues.clear();
  }
}

export const eventQueue = new EventQueue(100);

