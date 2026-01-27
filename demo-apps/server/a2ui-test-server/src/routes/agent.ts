/**
 * A2UI Agent Endpoint
 * Handles agent requests and streams A2UI JSONL messages via SSE
 */

import type { FastifyPluginAsync } from 'fastify';
import { validateA2UIRequest } from '../utils/validation.js';
import { JSONLEncoder } from '../streaming/jsonl-encoder.js';
import { sessionManager } from '../streaming/session.js';
import { createAgent } from './agent-factory.js';
import { loadConfig } from '../utils/config.js';
import { logger } from '../utils/logger.js';

const config = loadConfig();

export const agentRoute: FastifyPluginAsync = async (fastify) => {
  fastify.post('/agent', async (request, reply) => {
    const startTime = Date.now();

    try {
      // Validate input
      validateA2UIRequest(request.body);
      const input = request.body;

      logger.info(
        {
          threadId: input.threadId,
          runId: input.runId,
          messageLength: input.message.length,
          surfaceId: input.surfaceId,
        },
        'Received A2UI agent request'
      );

      // Update session
      const session = sessionManager.getOrCreate(input.threadId);
      if (input.surfaceId) {
        sessionManager.addSurface(session.sessionId, input.surfaceId);
      }

      // Create agent
      const agent = createAgent();

      // Set up SSE response
      reply.raw.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
      reply.raw.setHeader('Cache-Control', 'no-cache');
      reply.raw.setHeader('Connection', 'keep-alive');
      reply.raw.setHeader('X-Accel-Buffering', 'no'); // Disable nginx buffering

      // Send initial SSE retry directive
      const encoder = new JSONLEncoder();
      reply.raw.write(JSONLEncoder.retry(config.sseRetryMs));

      // Stream A2UI messages
      let messageCount = 0;
      for await (const message of agent.run(input)) {
        const encoded = encoder.encode(message);
        reply.raw.write(encoded);
        messageCount++;

        // Log progress
        if (messageCount % 10 === 0) {
          logger.debug({ threadId: input.threadId, messageCount }, 'Streaming A2UI messages');
        }
      }

      logger.info(
        {
          threadId: input.threadId,
          runId: input.runId,
          messageCount,
          duration: Date.now() - startTime,
        },
        'A2UI agent request completed'
      );

      // End SSE stream
      reply.raw.end();
    } catch (error) {
      logger.error(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
          stack: error instanceof Error ? error.stack : undefined,
        },
        'Error handling A2UI agent request'
      );

      if (!reply.sent) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        reply.code(500).send({
          error: {
            message: `Failed to process request: ${errorMessage}`,
          },
        });
      }
    }
  });
};
