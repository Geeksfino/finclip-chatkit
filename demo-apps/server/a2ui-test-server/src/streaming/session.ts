/**
 * Session Management for A2UI Server
 * Tracks active sessions and their state
 */

export interface A2UISession {
  sessionId: string;
  threadId: string;
  surfaceIds: Set<string>;
  createdAt: number;
  lastActivity: number;
}

/**
 * Session Manager
 */
export class SessionManager {
  private sessions: Map<string, A2UISession> = new Map();

  constructor(private timeoutMs: number = 3600000) {}

  /**
   * Get or create a session
   */
  getOrCreate(threadId: string, sessionId?: string): A2UISession {
    const id = sessionId || threadId;
    
    if (this.sessions.has(id)) {
      const session = this.sessions.get(id)!;
      session.lastActivity = Date.now();
      return session;
    }

    const session: A2UISession = {
      sessionId: id,
      threadId,
      surfaceIds: new Set(),
      createdAt: Date.now(),
      lastActivity: Date.now(),
    };

    this.sessions.set(id, session);
    return session;
  }

  /**
   * Get session by ID
   */
  get(sessionId: string): A2UISession | undefined {
    return this.sessions.get(sessionId);
  }

  /**
   * Add a surface to a session
   */
  addSurface(sessionId: string, surfaceId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.surfaceIds.add(surfaceId);
      session.lastActivity = Date.now();
    }
  }

  /**
   * Remove a surface from a session
   */
  removeSurface(sessionId: string, surfaceId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.surfaceIds.delete(surfaceId);
      session.lastActivity = Date.now();
    }
  }

  /**
   * Delete a session
   */
  delete(sessionId: string): void {
    this.sessions.delete(sessionId);
  }

  /**
   * Get session count
   */
  getSessionCount(): number {
    return this.sessions.size;
  }

  /**
   * Cleanup expired sessions
   */
  cleanup(maxAgeMs?: number): number {
    const maxAge = maxAgeMs || this.timeoutMs;
    const now = Date.now();
    let cleaned = 0;

    for (const [sessionId, session] of this.sessions.entries()) {
      if (now - session.lastActivity > maxAge) {
        this.sessions.delete(sessionId);
        cleaned++;
      }
    }

    return cleaned;
  }
}

// Singleton instance
export const sessionManager = new SessionManager();
