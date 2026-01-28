/**
 * MCP-UI / MCP Apps Test Server
 * Main entry point
 *
 * A test server implementing the MCP-UI protocol for ChatKit SDK integration testing.
 * Uses Fastify framework for HTTP handling.
 */

import Fastify from 'fastify';
import cors from '@fastify/cors';
import { config } from './utils/config.js';
import { logger, loggerOptions } from './utils/logger.js';
import { healthRoute, setSessionCountGetter } from './routes/health.js';
import { toolsRoute } from './routes/tools.js';
import { mcpRoute, getSessionCount } from './routes/mcp.js';

// Create Fastify instance
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
  exposedHeaders: ['Mcp-Session-Id'],
  allowedHeaders: ['Content-Type', 'mcp-session-id', 'Accept'],
});

// Inject session count getter into health route
setSessionCountGetter(getSessionCount);

// Register routes
await fastify.register(healthRoute);
await fastify.register(toolsRoute);
await fastify.register(mcpRoute);

// Root endpoint
fastify.get('/', async (_request, _reply) => {
  return {
    name: 'MCP-UI / MCP Apps Test Server',
    version: config.version,
    protocol: 'MCP-UI',
    protocolSpec: 'https://mcpui.dev/',
    endpoints: {
      health: 'GET /health',
      tools: 'GET /tools',
      mcp: {
        initialize: 'POST /mcp (with initialize request)',
        request: 'POST /mcp (with mcp-session-id header)',
        stream: 'GET /mcp (with mcp-session-id header)',
        close: 'DELETE /mcp (with mcp-session-id header)',
      },
    },
    docs: 'https://github.com/anthropics/anthropic-cookbook/tree/main/misc/model_context_protocol',
  };
});

// Session cleanup interval (every 10 minutes)
const cleanupInterval = setInterval(() => {
  logger.debug('Running session cleanup...');
}, 600000);

// Graceful shutdown
const shutdown = async () => {
  logger.info('Shutting down server...');
  clearInterval(cleanupInterval);
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
      name: config.name,
      version: config.version,
    },
    `🚀 MCP-UI Test Server running at http://${config.host}:${config.port}`
  );
  logger.info('📡 MCP endpoint: POST/GET/DELETE /mcp');
  logger.info('❤️  Health check: GET /health');
  logger.info('🔧 Tools list: GET /tools');
} catch (error) {
  logger.error({ error }, 'Failed to start server');
  process.exit(1);
}
