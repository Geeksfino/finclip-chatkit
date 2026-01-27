/**
 * Health check endpoint
 */

import type { FastifyPluginAsync } from 'fastify';
import { sessionManager } from '../streaming/session.js';

const startTime = Date.now();

export const healthRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', async (_request, _reply) => {
    const uptime = (Date.now() - startTime) / 1000;

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime,
      sessions: sessionManager.getSessionCount(),
      version: '1.0.0',
    };
  });
};
