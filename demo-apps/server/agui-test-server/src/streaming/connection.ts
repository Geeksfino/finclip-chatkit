/**
 * SSE Connection Management
 * Tracks active Server-Sent Events connections per session
 */

import type { FastifyReply } from 'fastify';
import type { BaseEvent } from '../types/agui.js';
import { SSEEncoder } from './encoder.js';
import { logger } from '../utils/logger.js';

export interface SSEConnection {
  sessionId: string;
  reply: FastifyReply;
  connectedAt: Date;
  lastActivity: Date;
}

export class SSEConnectionManager {
  private connections = new Map<string, SSEConnection>();
  private encoder = new SSEEncoder('text/event-stream');

  /**
   * Register a new SSE connection for a session
   */
  register(sessionId: string, reply: FastifyReply): void {
    const connection: SSEConnection = {
      sessionId,
      reply,
      connectedAt: new Date(),
      lastActivity: new Date(),
    };

    this.connections.set(sessionId, connection);
    logger.info({ sessionId }, 'Registered SSE connection');
  }

  /**
   * Unregister an SSE connection
   */
  unregister(sessionId: string): void {
    const connection = this.connections.get(sessionId);
    if (connection) {
      this.connections.delete(sessionId);
      logger.info({ sessionId }, 'Unregistered SSE connection');
    }
  }

  /**
   * Check if a session has an active SSE connection
   */
  hasConnection(sessionId: string): boolean {
    return this.connections.has(sessionId);
  }

  /**
   * Send an event to a specific session's SSE connection
   * Returns true if event was sent, false if no connection exists
   */
  sendEvent(sessionId: string, event: BaseEvent): boolean {
    const connection = this.connections.get(sessionId);
    if (!connection) {
      return false;
    }

    try {
      // Update last activity
      connection.lastActivity = new Date();

      // Encode and send event
      const encoded = this.encoder.encode(event);
      connection.reply.raw.write(encoded);

      return true;
    } catch (error) {
      logger.error({ error, sessionId }, 'Failed to send event to SSE connection');
      // Connection might be closed, unregister it
      this.unregister(sessionId);
      return false;
    }
  }

  /**
   * Send multiple events to a session
   */
  sendEvents(sessionId: string, events: BaseEvent[]): number {
    let sent = 0;
    for (const event of events) {
      if (this.sendEvent(sessionId, event)) {
        sent++;
      }
    }
    return sent;
  }

  /**
   * Get all active session IDs
   */
  getAllSessionIds(): string[] {
    return Array.from(this.connections.keys());
  }

  /**
   * Get connection info for a session
   */
  getConnection(sessionId: string): SSEConnection | undefined {
    return this.connections.get(sessionId);
  }

  /**
   * Clean up stale connections (older than maxAgeMs)
   */
  cleanup(maxAgeMs: number = 300000): number {
    const now = Date.now();
    let cleaned = 0;

    for (const [sessionId, connection] of this.connections.entries()) {
      if (now - connection.lastActivity.getTime() > maxAgeMs) {
        try {
          connection.reply.raw.end();
        } catch (error) {
          // Ignore errors when closing stale connections
        }
        this.connections.delete(sessionId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logger.info({ cleaned }, 'Cleaned up stale SSE connections');
    }

    return cleaned;
  }

  /**
   * Get the number of active connections
   */
  get size(): number {
    return this.connections.size;
  }
}

export const sseConnectionManager = new SSEConnectionManager();

