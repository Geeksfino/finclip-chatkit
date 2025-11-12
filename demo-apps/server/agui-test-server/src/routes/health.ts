/**
 * Health Check Endpoint
 */

import type { FastifyPluginAsync } from 'fastify';
import { sessionManager } from '../streaming/session.js';
import { sseConnectionManager } from '../streaming/connection.js';

export const healthRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', async (_request, _reply) => {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      sessions: sessionManager.size,
      sseConnections: sseConnectionManager.size,
    };
  });
};
