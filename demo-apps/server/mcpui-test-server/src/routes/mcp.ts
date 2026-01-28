/**
 * MCP Protocol Endpoints
 *
 * Handles MCP communication using StreamableHTTPServerTransport.
 * Uses raw Node.js request/response objects for compatibility with MCP SDK.
 */

import type { FastifyPluginAsync, FastifyRequest, FastifyReply } from 'fastify';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { isInitializeRequest } from '@modelcontextprotocol/sdk/types.js';
import { randomUUID } from 'crypto';
import { logger } from '../utils/logger.js';
import { config } from '../utils/config.js';
import { SessionManager } from '../mcp/session.js';
import { registerTools } from '../tools/index.js';

// Session manager
const sessionManager = new SessionManager(config.sessionTimeout);

// Store transports by session ID
const transports: { [sessionId: string]: StreamableHTTPServerTransport } = {};

// Export session count getter for health check
export function getSessionCount(): number {
  return sessionManager.getSessionCount();
}

export const mcpRoute: FastifyPluginAsync = async (fastify) => {
  // MCP endpoint - POST for client-to-server communication
  fastify.post('/mcp', async (request: FastifyRequest, reply: FastifyReply) => {
    const sessionId = request.headers['mcp-session-id'] as string | undefined;
    logger.debug({ headers: request.headers, body: request.body }, 'Received MCP POST request');

    let transport: StreamableHTTPServerTransport;

    try {
      if (sessionId && transports[sessionId]) {
        // Reuse existing transport
        transport = transports[sessionId];
        logger.debug({ sessionId }, 'Reusing existing transport');
      } else if (!sessionId && isInitializeRequest(request.body)) {
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
        return reply.status(400).send({
          error: { message: 'Bad Request: No valid session ID provided' },
        });
      }

      // Handle the request using raw Node.js objects
      // StreamableHTTPServerTransport expects Node.js IncomingMessage and ServerResponse
      await transport.handleRequest(request.raw, reply.raw, request.body as Record<string, unknown>);

      // Mark reply as sent since we're handling response through raw
      reply.hijack();
    } catch (error) {
      logger.error({ error, sessionId }, 'Error handling MCP request');
      logger.error(
        { errorStack: (error as Error).stack, errorMessage: (error as Error).message },
        'Full error details'
      );

      // Only send error if reply hasn't been sent
      if (!reply.sent) {
        return reply.status(500).send({
          error: { message: 'Internal server error' },
        });
      }
    }
  });

  // MCP endpoint - GET for server-to-client stream
  fastify.get('/mcp', async (request: FastifyRequest, reply: FastifyReply) => {
    const sessionId = request.headers['mcp-session-id'] as string | undefined;

    if (!sessionId || !transports[sessionId]) {
      return reply.status(404).send('Session not found');
    }

    const transport = transports[sessionId];

    // Use raw objects for SSE streaming
    await transport.handleRequest(request.raw, reply.raw);
    reply.hijack();
  });

  // MCP endpoint - DELETE for session termination
  fastify.delete('/mcp', async (request: FastifyRequest, reply: FastifyReply) => {
    const sessionId = request.headers['mcp-session-id'] as string | undefined;

    if (!sessionId || !transports[sessionId]) {
      return reply.status(404).send('Session not found');
    }

    const transport = transports[sessionId];
    await transport.handleRequest(request.raw, reply.raw);
    reply.hijack();
  });
};
