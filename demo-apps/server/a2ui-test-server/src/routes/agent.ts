/**
 * A2UI Agent Endpoint
 * Handles agent requests (A2A Message format) and streams A2UI JSONL messages via SSE
 */

import type { FastifyPluginAsync } from 'fastify';
import {
  validateA2AMessageRequest,
  normalizeA2AMessageToAgentInput,
  generateRunId,
} from '../utils/validation.js';
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
      // Validate A2A Message format
      validateA2AMessageRequest(request.body);

      // Normalize to internal agent input
      const input = normalizeA2AMessageToAgentInput(request.body);

      // Ensure threadId for session (generate if not provided)
      const threadId = input.threadId ?? `thread_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      const runId = input.runId ?? generateRunId();
      const agentInput = { ...input, threadId, runId };

      logger.info(
        {
          threadId: agentInput.threadId,
          runId: agentInput.runId,
          messageLength: agentInput.message.length,
          surfaceId: agentInput.surfaceId,
        },
        'Received A2UI agent request (A2A Message format)'
      );

      // Update session
      const session = sessionManager.getOrCreate(threadId);
      if (agentInput.surfaceId) {
        sessionManager.addSurface(session.sessionId, agentInput.surfaceId);
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
      for await (const message of agent.run(agentInput)) {
        const encoded = encoder.encode(message);
        reply.raw.write(encoded);
        messageCount++;

        // Log progress
        if (messageCount % 10 === 0) {
          logger.debug({ threadId: agentInput.threadId, messageCount }, 'Streaming A2UI messages');
        }
      }

      logger.info(
        {
          threadId: agentInput.threadId,
          runId: agentInput.runId,
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
