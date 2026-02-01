/**
 * AG-UI Test Server
 * Main entry point
 */

import Fastify from 'fastify';
import cors from '@fastify/cors';
import { loadConfig } from './utils/config.js';
import { logger, loggerOptions } from './utils/logger.js';
import { agentRoute } from './routes/agent.js';
import { eventsRoute } from './routes/events.js';
import { healthRoute } from './routes/health.js';
import { scenariosRoute } from './routes/scenarios.js';
import { sessionManager } from './streaming/session.js';
import { sseConnectionManager } from './streaming/connection.js';
import { mcpClientManager } from './mcp/index.js';

const config = loadConfig();

// MCP client init when extensionMode is mcpui (non-blocking)
if (config.extensionMode === 'mcpui' && config.mcp.enabled) {
  Promise.race([
    mcpClientManager.connect(config.mcp.serverId, {
      url: config.mcp.serverUrl,
      timeout: config.mcp.connectTimeoutMs,
    }),
    new Promise<never>((_, reject) =>
      setTimeout(() => reject(new Error('MCP connect timeout')), config.mcp.connectTimeoutMs)
    ),
  ])
    .then(() => {
      const tools = mcpClientManager.getTools(config.mcp.serverId);
      logger.info(
        { serverId: config.mcp.serverId, url: config.mcp.serverUrl, toolCount: tools.length },
        'MCP client connected'
      );
    })
    .catch((err) => {
      logger.warn(
        { serverId: config.mcp.serverId, url: config.mcp.serverUrl, error: String(err) },
        'MCP client connection failed - service continues without MCPUI tools'
      );
    });
} else if (config.extensionMode === 'mcpui') {
  logger.info('MCP integration disabled (extensionMode=mcpui but mcp.enabled=false)');
}

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
await fastify.register(eventsRoute);
await fastify.register(agentRoute);
await fastify.register(scenariosRoute);

// Root endpoint
fastify.get('/', async (_request, _reply) => {
  return {
    name: 'AG-UI Test Server',
    version: '1.0.0',
    agentMode: config.agentMode,
    defaultScenario: config.defaultScenario,
    endpoints: {
      health: 'GET /health',
      events: 'GET /events?sessionId=<uuid>',
      agent: 'POST /agent',
      scenarios: {
        list: 'GET /scenarios',
        get: 'GET /scenarios/:id',
        run: 'POST /scenarios/:id',
      },
    },
    docs: 'https://docs.ag-ui.com',
  };
});

// Session cleanup interval (every 10 minutes)
setInterval(() => {
  sessionManager.cleanup(3600000); // 1 hour max age
  sseConnectionManager.cleanup(300000); // 5 minutes max age for SSE connections
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
      defaultScenario: config.defaultScenario,
      extensionMode: config.extensionMode,
      llmProvider: config.llm.provider,
      llmModel: config.llm.model,
    },
    'AG-UI Test Server started'
  );
} catch (error) {
  logger.error({ error }, 'Failed to start server');
  process.exit(1);
}
