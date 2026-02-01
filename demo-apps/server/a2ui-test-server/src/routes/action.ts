/**
 * Action Endpoint
 * Handles user interactions (userAction) and errors from A2UI clients
 */

import type { FastifyPluginAsync, FastifyReply } from 'fastify';
import { validateClientEventMessage } from '../utils/validation.js';
import { logger } from '../utils/logger.js';
import { JSONLEncoder } from '../streaming/jsonl-encoder.js';
import { loadConfig } from '../utils/config.js';
import type { ClientEventMessage } from '../types/a2ui.js';
import { STANDARD_CATALOG_ID } from '../constants/catalog.js';

const config = loadConfig();

/**
 * Handle A2UI client event (userAction or error).
 * Exported for reuse by /action and /a2a/action.
 */
export async function handleClientEvent(
  event: ClientEventMessage,
  reply: FastifyReply
): Promise<void> {
  logger.info(
    {
      eventType: 'userAction' in event ? 'userAction' : 'error',
      actionName: 'userAction' in event ? event.userAction.name : undefined,
      surfaceId: 'userAction' in event ? event.userAction.surfaceId : undefined,
    },
    'Received client event'
  );

  if ('userAction' in event) {
    const { userAction } = event;
    logger.info(
      {
        actionName: userAction.name,
        surfaceId: userAction.surfaceId,
        sourceComponentId: userAction.sourceComponentId,
        context: userAction.context,
      },
      'Processing user action'
    );

    const responseMessages = generateActionResponse(userAction);

    if (responseMessages.length > 0) {
      reply.raw.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
      reply.raw.setHeader('Cache-Control', 'no-cache');
      reply.raw.setHeader('Connection', 'keep-alive');

      const encoder = new JSONLEncoder();
      reply.raw.write(JSONLEncoder.retry(config.sseRetryMs));

      for (const message of responseMessages) {
        reply.raw.write(encoder.encode(message));
      }

      reply.raw.end();
    } else {
      reply.send({ status: 'ok', message: 'Action received' });
    }
  } else if ('error' in event) {
    logger.error({ error: event.error }, 'Client reported error');
    reply.send({ status: 'ok', message: 'Error logged' });
  }
}

export const actionRoute: FastifyPluginAsync = async (fastify) => {
  fastify.post('/action', async (request, reply) => {
    try {
      validateClientEventMessage(request.body);
      await handleClientEvent(request.body as ClientEventMessage, reply);
    } catch (error) {
      logger.error(
        { error: error instanceof Error ? error.message : 'Unknown error' },
        'Error handling client action'
      );
      if (!reply.sent) {
        reply.code(400).send({
          error: {
            message: error instanceof Error ? error.message : 'Invalid request',
          },
        });
      }
    }
  });
};

/**
 * Generate response messages for a user action
 * This is a simple demo - in production, this would trigger business logic
 */
function generateActionResponse(userAction: {
  name: string;
  surfaceId: string;
  sourceComponentId: string;
  context: Record<string, unknown>;
}): Array<import('../types/a2ui.js').A2UIMessage> {
  const messages: Array<import('../types/a2ui.js').A2UIMessage> = [];

  // Example: Handle increment/decrement actions
  if (userAction.name === 'increment' || userAction.name === 'decrement') {
    const currentValue = (userAction.context.currentValue as number) || 0;
    const newValue = userAction.name === 'increment' ? currentValue + 1 : currentValue - 1;

    // Update data model
    messages.push({
      dataModelUpdate: {
        surfaceId: userAction.surfaceId,
        path: 'counter',
        contents: [
          {
            key: 'value',
            valueNumber: newValue,
          },
        ],
      },
    });
  }

  // Example: Handle form submission
  if (userAction.name === 'submit_form' || userAction.name === 'submit_registration') {
    // Create a confirmation UI
    messages.push({
      surfaceUpdate: {
        surfaceId: userAction.surfaceId,
        components: [
          {
            id: 'confirmation-root',
            component: {
              Column: {
                children: {
                  explicitList: ['confirmation-text'],
                },
              },
            },
          },
          {
            id: 'confirmation-text',
            component: {
              Text: {
                text: {
                  literalString: `Form submitted successfully! Data: ${JSON.stringify(userAction.context)}`,
                },
              },
            },
          },
        ],
      },
    });

    messages.push({
      dataModelUpdate: {
        surfaceId: userAction.surfaceId,
        contents: [],
      },
    });

    messages.push({
      beginRendering: {
        surfaceId: userAction.surfaceId,
        root: 'confirmation-root',
        catalogId: STANDARD_CATALOG_ID,
      },
    });
  }

  return messages;
}
