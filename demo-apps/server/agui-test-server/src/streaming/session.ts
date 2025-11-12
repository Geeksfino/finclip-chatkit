/**
 * Session Management
 */

import type { SessionState } from '../types/agui.js';
import type { Message } from '@ag-ui/core';
import { logger } from '../utils/logger.js';

export class SessionManager {
  private sessions = new Map<string, SessionState>();

  getOrCreate(threadId: string): SessionState {
    let session = this.sessions.get(threadId);
    
    if (!session) {
      session = {
        threadId,
        messages: [],
        createdAt: new Date(),
        lastActivity: new Date(),
      };
      this.sessions.set(threadId, session);
      logger.info({ threadId }, 'Created new session');
    } else {
      session.lastActivity = new Date();
    }

    return session;
  }

  updateMessages(threadId: string, messages: Message[]): void {
    const session = this.sessions.get(threadId);
    if (session) {
      session.messages = messages;
      session.lastActivity = new Date();
    }
  }

  get(threadId: string): SessionState | undefined {
    return this.sessions.get(threadId);
  }

  delete(threadId: string): boolean {
    logger.info({ threadId }, 'Deleted session');
    return this.sessions.delete(threadId);
  }

  cleanup(maxAgeMs: number = 3600000): number {
    const now = Date.now();
    let cleaned = 0;

    for (const [threadId, session] of this.sessions.entries()) {
      if (now - session.lastActivity.getTime() > maxAgeMs) {
        this.sessions.delete(threadId);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      logger.info({ cleaned }, 'Cleaned up stale sessions');
    }

    return cleaned;
  }

  get size(): number {
    return this.sessions.size;
  }
}

export const sessionManager = new SessionManager();
