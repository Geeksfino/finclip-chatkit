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

export async function startServer() {
  const config = loadConfig();

  const fastify = Fastify({
    logger: loggerOptions,
    requestIdHeader: 'x-request-id',
    requestIdLogLabel: 'reqId',
    disableRequestLogging: false,
    trustProxy: true,
  });

  await fastify.register(cors, {
    origin: config.corsOrigin,
    credentials: true,
  });

  await fastify.register(healthRoute);
  await fastify.register(eventsRoute);
  await fastify.register(agentRoute);
  await fastify.register(scenariosRoute);

  fastify.get('/', async (_request, _reply) => {
    return {
      name: 'AG-UI Test Server',
      version: '1.0.0',
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

  setInterval(() => {
    sessionManager.cleanup(3600000); // 1 hour max age
    sseConnectionManager.cleanup(300000); // 5 minutes max age for SSE connections
  }, 600000);

  const shutdown = async () => {
    logger.info('Shutting down server...');
    await fastify.close();
    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

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
        llmProvider: config.llmProvider,
      },
      'AG-UI Test Server started'
    );
  } catch (error) {
    logger.error({ error }, 'Failed to start server');
    process.exit(1);
  }
}
