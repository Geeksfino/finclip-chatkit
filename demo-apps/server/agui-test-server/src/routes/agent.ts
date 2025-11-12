/**
 * Main AG-UI Agent Endpoint
 */

import type { FastifyPluginAsync } from 'fastify';
import type { RunAgentInput } from '@ag-ui/core';
import { validateRunAgentInput } from '../utils/validation.js';
import { SSEEncoder, streamEvents } from '../streaming/encoder.js';
import { sessionManager } from '../streaming/session.js';
import { sseConnectionManager } from '../streaming/connection.js';
import { eventQueue } from '../streaming/event-queue.js';
import { createAgent } from './agent-factory';
import { logger } from '../utils/logger.js';
import { loadConfig } from '../utils/config.js';

const config = loadConfig();

export const agentRoute: FastifyPluginAsync = async (fastify) => {
  fastify.post<{ Body: RunAgentInput }>('/agent', async (request, reply) => {
    const startTime = Date.now();

    try {
      // Validate input
      validateRunAgentInput(request.body);
      const input = request.body as RunAgentInput;

      // Count tools from the proper tools array (AG-UI compliant)
      const toolsCount = input.tools?.length || 0;

      logger.info(
        {
          threadId: input.threadId,
          runId: input.runId,
          messageCount: input.messages.length,
          toolCount: toolsCount,
        },
        'Received agent request'
      );

      // Update session
      sessionManager.getOrCreate(input.threadId);
      sessionManager.updateMessages(input.threadId, input.messages);

      // Check if this is eventStream mode (has active SSE connection)
      // threadId equals sessionId.uuidString in NeuronKit
      const hasSSEConnection = sseConnectionManager.hasConnection(input.threadId);

      if (hasSSEConnection) {
        // EventStream mode: Route events to existing SSE connection
        logger.info(
          {
            threadId: input.threadId,
            runId: input.runId,
          },
          'Routing events to SSE connection (eventStream mode)'
        );

        // Create and run agent
        const agent = await createAgent(config, input);
        const events = agent.run(input);

        // Send events to SSE connection
        let eventCount = 0;
        for await (const event of events) {
          const sent = sseConnectionManager.sendEvent(input.threadId, event);
          if (sent) {
            eventCount++;
          } else {
            // Connection lost, queue event
            eventQueue.enqueue(input.threadId, event);
          }
        }

        const duration = Date.now() - startTime;
        logger.info(
          {
            threadId: input.threadId,
            runId: input.runId,
            duration,
            eventCount,
          },
          'Completed agent request (routed to SSE)'
        );

        // Return 200 OK immediately (events sent via SSE)
        reply.status(200).send({ status: 'ok', eventsSent: eventCount });
      } else {
        // PostStream mode: Stream events via POST response
        logger.info(
          {
            threadId: input.threadId,
            runId: input.runId,
          },
          'Streaming events via POST response (postStream mode)'
        );

        // Create encoder
        const acceptHeader = request.headers.accept;
        const encoder = new SSEEncoder(acceptHeader);

        // Set SSE headers
        reply.raw.writeHead(200, {
          'Content-Type': encoder.getContentType(),
          'Cache-Control': 'no-cache',
          Connection: 'keep-alive',
          'X-Accel-Buffering': 'no',
        });

        // Send retry directive
        reply.raw.write(SSEEncoder.retry(config.sseRetryMs));

        // Create and run agent
        const agent = await createAgent(config, input);
        const events = agent.run(input);

        // Stream events
        for await (const chunk of streamEvents(events, encoder)) {
          reply.raw.write(chunk);
        }

        const duration = Date.now() - startTime;
        logger.info(
          {
            threadId: input.threadId,
            runId: input.runId,
            duration,
          },
          'Completed agent request (streamed via POST)'
        );

        reply.raw.end();
      }
    } catch (error) {
      const duration = Date.now() - startTime;
      
      // Build detailed error information
      const errorInfo: any = {
        duration,
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        errorName: error instanceof Error ? error.name : 'UnknownError',
      };

      // Add request details if available
      if (request.body) {
        const body = request.body as any;
        errorInfo.threadId = body.threadId;
        errorInfo.runId = body.runId;
        errorInfo.messageCount = body.messages?.length || 0;
        errorInfo.toolCount = body.tools?.length || 0;
        
        // Include tool names if tools were provided
        if (body.tools && body.tools.length > 0) {
          errorInfo.toolNames = body.tools.map((t: any) => t.name);
        }
      }

      // Add stack trace if available
      if (error instanceof Error && error.stack) {
        errorInfo.stack = error.stack;
      }

      logger.error(errorInfo, 'Agent request failed');

      if (!reply.sent) {
        reply.status(500).send({
          error: 'Internal Server Error',
          message: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }
  });
};
