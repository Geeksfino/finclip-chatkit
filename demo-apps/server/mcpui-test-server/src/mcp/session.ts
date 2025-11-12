import { MCPSession } from '../types/index.js';
import { logger } from '../utils/logger.js';

export class SessionManager {
  private sessions: Map<string, MCPSession> = new Map();
  private sessionTimeout: number;

  constructor(sessionTimeout: number = 3600000) {
    this.sessionTimeout = sessionTimeout;
    this.startCleanupTimer();
  }

  createSession(sessionId: string): MCPSession {
    const session: MCPSession = {
      sessionId,
      createdAt: new Date(),
      lastActivity: new Date(),
    };
    
    this.sessions.set(sessionId, session);
    logger.info({ sessionId }, 'Session created');
    
    return session;
  }

  getSession(sessionId: string): MCPSession | undefined {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.lastActivity = new Date();
    }
    return session;
  }

  deleteSession(sessionId: string): boolean {
    const deleted = this.sessions.delete(sessionId);
    if (deleted) {
      logger.info({ sessionId }, 'Session deleted');
    }
    return deleted;
  }

  getSessionCount(): number {
    return this.sessions.size;
  }

  private startCleanupTimer(): void {
    setInterval(() => {
      const now = Date.now();
      const expiredSessions: string[] = [];

      for (const [sessionId, session] of this.sessions.entries()) {
        const age = now - session.lastActivity.getTime();
        if (age > this.sessionTimeout) {
          expiredSessions.push(sessionId);
        }
      }

      for (const sessionId of expiredSessions) {
        this.deleteSession(sessionId);
        logger.info({ sessionId }, 'Session expired and removed');
      }
    }, 60000); // Check every minute
  }
}
