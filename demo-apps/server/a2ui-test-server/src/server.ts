/**
 * A2UI Test Server
 * Main entry point
 */

import Fastify from 'fastify';
import cors from '@fastify/cors';
import { loadConfig } from './utils/config.js';
import { logger, loggerOptions } from './utils/logger.js';
import { agentRoute } from './routes/agent.js';
import { actionRoute } from './routes/action.js';
import { a2aRoute } from './routes/a2a.js';
import { healthRoute } from './routes/health.js';
import { sessionManager } from './streaming/session.js';

const config = loadConfig();

const fastify = Fastify({
  logger: loggerOptions,
  requestIdHeader: 'x-request-id',
  requestIdLogLabel: 'reqId',
  disableRequestLogging: false,
  trustProxy: true,
});

// Register CORS
await fastify.register(cors, {
  origin: config.corsOrigin,
  credentials: true,
});

// Register routes
await fastify.register(healthRoute);
await fastify.register(agentRoute);
await fastify.register(actionRoute);
await fastify.register(a2aRoute, { prefix: '/a2a' });

// Root endpoint
fastify.get('/', async (_request, _reply) => {
  return {
    name: 'A2UI Test Server',
    version: '1.0.0',
    agentMode: config.agentMode,
    endpoints: {
      health: 'GET /health',
      agent: 'POST /agent',
      action: 'POST /action',
      a2aCard: 'GET /a2a/card',
      a2aAction: 'POST /a2a/action',
    },
    docs: 'https://a2ui.org/',
  };
});

// Session cleanup interval (every 10 minutes)
setInterval(() => {
  const cleaned = sessionManager.cleanup(3600000); // 1 hour max age
  if (cleaned > 0) {
    logger.debug({ cleaned }, 'Cleaned up expired sessions');
  }
}, 600000);

// Graceful shutdown
const shutdown = async () => {
  logger.info('Shutting down server...');
  await fastify.close();
  process.exit(0);
};

process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

// Start server
try {
  await fastify.listen({
    port: config.port,
    host: config.host,
  });

  logger.info(
    {
      port: config.port,
      host: config.host,
      agentMode: config.agentMode,
    },
    `🚀 A2UI Test Server running at http://${config.host}:${config.port}`
  );
} catch (error) {
  logger.error(
    {
      error: error instanceof Error ? error.message : 'Unknown error',
      stack: error instanceof Error ? error.stack : undefined,
    },
    'Failed to start server'
  );
  process.exit(1);
}
