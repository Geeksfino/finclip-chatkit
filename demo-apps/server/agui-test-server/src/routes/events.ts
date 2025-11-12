/**
 * GET /events Endpoint
 * Establishes persistent SSE connections for eventStream mode
 */

import type { FastifyPluginAsync } from 'fastify';
import { SSEEncoder } from '../streaming/encoder.js';
import { sseConnectionManager } from '../streaming/connection.js';
import { eventQueue } from '../streaming/event-queue.js';
import { sessionManager } from '../streaming/session.js';
import { logger } from '../utils/logger.js';
import { loadConfig } from '../utils/config.js';

const config = loadConfig();

export const eventsRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get<{ Querystring: { sessionId?: string } }>('/events', async (request, reply) => {
    const sessionId = request.query.sessionId;

    if (!sessionId) {
      return reply.status(400).send({
        error: 'Missing sessionId query parameter',
        message: 'GET /events requires ?sessionId=<uuid>',
      });
    }

    // Validate sessionId format (should be UUID)
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!uuidRegex.test(sessionId)) {
      return reply.status(400).send({
        error: 'Invalid sessionId format',
        message: 'sessionId must be a valid UUID',
      });
    }

    logger.info({ sessionId }, 'Establishing SSE connection');

    // Create encoder
    const encoder = new SSEEncoder(request.headers.accept);

    // Set SSE headers
    reply.raw.writeHead(200, {
      'Content-Type': encoder.getContentType(),
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    });

    // Send retry directive
    reply.raw.write(SSEEncoder.retry(config.sseRetryMs));

    // Register this connection
    sseConnectionManager.register(sessionId, reply);

    // Ensure session exists in session manager
    sessionManager.getOrCreate(sessionId);

    // Send any queued events immediately
    const queuedEvents = eventQueue.dequeueAll(sessionId);
    if (queuedEvents.length > 0) {
      logger.info({ sessionId, count: queuedEvents.length }, 'Sending queued events');
      for (const event of queuedEvents) {
        const encoded = encoder.encode(event);
        reply.raw.write(encoded);
      }
    }

    // Set up heartbeat interval to keep connection alive
    const heartbeatInterval = setInterval(() => {
      try {
        reply.raw.write(SSEEncoder.comment('heartbeat'));
      } catch (error) {
        // Connection closed, stop heartbeat
        clearInterval(heartbeatInterval);
        sseConnectionManager.unregister(sessionId);
      }
    }, config.sseHeartbeatMs);

    // Handle connection close
    request.raw.on('close', () => {
      clearInterval(heartbeatInterval);
      sseConnectionManager.unregister(sessionId);
      logger.info({ sessionId }, 'SSE connection closed');
    });

    // Keep connection open (don't call reply.raw.end() here)
    // Connection will be closed by client or timeout
  });
};

