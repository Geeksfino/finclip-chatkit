/**
 * Health Check Endpoint
 */

import type { FastifyPluginAsync } from 'fastify';
import type { HealthStatus } from '../types/index.js';
import { config } from '../utils/config.js';

// Start time for uptime calculation
const startTime = Date.now();

// Session count getter (will be injected)
let getSessionCount: () => number = () => 0;

export function setSessionCountGetter(getter: () => number): void {
  getSessionCount = getter;
}

export const healthRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', async (_request, _reply) => {
    const health: HealthStatus = {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: (Date.now() - startTime) / 1000,
      sessions: getSessionCount(),
      version: config.version,
    };

    return health;
  });
};
