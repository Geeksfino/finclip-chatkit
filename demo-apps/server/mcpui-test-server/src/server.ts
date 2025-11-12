import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { isInitializeRequest } from '@modelcontextprotocol/sdk/types.js';
import { randomUUID } from 'crypto';
import { logger } from './utils/logger.js';
import { SessionManager } from './mcp/session.js';
import { registerTools } from './tools/index.js';
import type { ServerConfig, HealthStatus } from './types/index.js';

// Load environment variables
dotenv.config();

// Server configuration
const config: ServerConfig = {
  port: parseInt(process.env.PORT || '3100'),
  host: process.env.HOST || '0.0.0.0',
  name: process.env.SERVER_NAME || 'mcpui-test-server',
  version: process.env.SERVER_VERSION || '1.0.0',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  sessionTimeout: parseInt(process.env.SESSION_TIMEOUT || '3600000'),
};

// Initialize Express app
const app = express();

// Middleware
app.use(cors({
  origin: config.corsOrigin,
  exposedHeaders: ['Mcp-Session-Id'],
  allowedHeaders: ['Content-Type', 'mcp-session-id'],
}));
app.use(express.json());

// Session manager
const sessionManager = new SessionManager(config.sessionTimeout);

// Store transports by session ID
const transports: { [sessionId: string]: StreamableHTTPServerTransport } = {};

// Start time for uptime calculation
const startTime = Date.now();

// Health check endpoint
app.get('/health', (req, res) => {
  const health: HealthStatus = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: (Date.now() - startTime) / 1000,
    sessions: sessionManager.getSessionCount(),
    version: config.version,
  };
  
  res.json(health);
});

// MCP endpoint - POST for client-to-server communication
app.post('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  logger.debug({ headers: req.headers, body: req.body }, 'Received MCP POST request');
  let transport: StreamableHTTPServerTransport;

  try {
    if (sessionId && transports[sessionId]) {
      // Reuse existing transport
      transport = transports[sessionId];
      logger.debug({ sessionId }, 'Reusing existing transport');
    } else if (!sessionId && isInitializeRequest(req.body)) {
      // Create new transport for initialization
      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (sid) => {
          transports[sid] = transport;
          sessionManager.createSession(sid);
          logger.info({ sessionId: sid }, 'MCP session initialized');
        },
      });

      // Clean up on close
      transport.onclose = () => {
        if (transport.sessionId) {
          logger.info({ sessionId: transport.sessionId }, 'MCP session closed');
          delete transports[transport.sessionId];
          sessionManager.deleteSession(transport.sessionId);
        }
      };

      // Create new MCP server instance
      const server = new McpServer({
        name: config.name,
        version: config.version,
      });

      // Register all tools
      registerTools(server);

      // Connect server to transport
      await server.connect(transport);
      logger.info('New MCP server instance created and connected');
    } else {
      return res.status(400).json({
        error: { message: 'Bad Request: No valid session ID provided' },
      });
    }

    // Handle the request
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    logger.error({ error, sessionId }, 'Error handling MCP request');
    logger.error({ errorStack: (error as Error).stack, errorMessage: (error as Error).message }, 'Full error details');
    res.status(500).json({
      error: { message: 'Internal server error' },
    });
  }
});

// MCP endpoint - GET for server-to-client stream
app.get('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  
  if (!sessionId || !transports[sessionId]) {
    return res.status(404).send('Session not found');
  }

  const transport = transports[sessionId];
  await transport.handleRequest(req, res);
});

// MCP endpoint - DELETE for session termination
app.delete('/mcp', async (req, res) => {
  const sessionId = req.headers['mcp-session-id'] as string | undefined;
  
  if (!sessionId || !transports[sessionId]) {
    return res.status(404).send('Session not found');
  }

  const transport = transports[sessionId];
  await transport.handleRequest(req, res);
});

// List all available tools
app.get('/tools', (req, res) => {
  // This would list all registered tools
  // For now, return a simple response
  res.json({
    tools: [
      'showSimpleHtml',
      'showInteractiveForm',
      'showComplexLayout',
      'showAnimatedContent',
      'showResponsiveCard',
      'showExampleSite',
      'showCustomUrl',
      'showApiDocs',
      'showRemoteDomButton',
      'showRemoteDomForm',
      'showRemoteDomChart',
      'showRemoteDomWebComponents',
      'showWithPreferredSize',
      'showWithRenderData',
      'showResponsiveLayout',
      'showAsyncToolCall',
      'showProgressIndicator',
    ],
  });
});

// Start server
app.listen(config.port, config.host, () => {
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
});
