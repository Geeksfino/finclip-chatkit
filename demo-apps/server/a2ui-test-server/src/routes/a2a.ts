/**
 * A2A-compatible endpoints for A2UI v0.8
 * - GET /a2a/card: Agent Card with A2UI capabilities
 * - POST /a2a/action: Client events via A2A Message wrapper (optional)
 */

import type { FastifyPluginAsync } from 'fastify';
import { STANDARD_CATALOG_ID } from '../constants/catalog.js';
import { validateClientEventMessage } from '../utils/validation.js';
import { handleClientEvent } from './action.js';
import { logger } from '../utils/logger.js';
import type { ClientEventMessage } from '../types/a2ui.js';

/** A2UI extension URI per spec */
const A2UI_EXTENSION_URI = 'https://a2ui.org/a2a-extension/a2ui/v0.8';

/**
 * Extract A2UI Client Event from A2A Message.
 * Supports: raw { userAction } | { error }, or A2A-wrapped { message: { clientEvent: {...} } }
 */
function extractClientEvent(body: unknown): { userAction?: unknown; error?: unknown } | null {
  if (!body || typeof body !== 'object') return null;
  const obj = body as Record<string, unknown>;

  // Raw client event (current /action format)
  if ('userAction' in obj || 'error' in obj) {
    return obj as { userAction?: unknown; error?: unknown };
  }

  // A2A Message wrapper: message.clientEvent
  const message = obj.message as Record<string, unknown> | undefined;
  const clientEvent = message?.clientEvent as Record<string, unknown> | undefined;
  if (clientEvent && ('userAction' in clientEvent || 'error' in clientEvent)) {
    return clientEvent as { userAction?: unknown; error?: unknown };
  }

  return null;
}

export const a2aRoute: FastifyPluginAsync = async (fastify) => {
  /**
   * GET /card (mounted at /a2a/card)
   * Returns Agent Card with A2UI capabilities (per A2UI v0.8 Catalog Negotiation)
   */
  fastify.get('/card', async (_request, reply) => {
    return reply.send({
      name: 'A2UI Test Server',
      description: 'A2UI v0.8 test server with scenario and LLM agents',
      capabilities: {
        extensions: [
          {
            uri: A2UI_EXTENSION_URI,
            params: {
              supportedCatalogIds: [STANDARD_CATALOG_ID],
              acceptsInlineCatalogs: false,
            },
          },
        ],
      },
    });
  });

  /**
   * POST /action (mounted at /a2a/action)
   * Accepts A2A Message format with client event (userAction/error).
   * Per A2UI v0.8: "user interactions are communicated back via an A2A message".
   * Delegates to the same logic as /action.
   */
  fastify.post('/action', async (request, reply) => {
    const event = extractClientEvent(request.body);
    if (!event) {
      return reply.code(400).send({
        error: {
          message:
            'Invalid A2A message: expected { userAction } | { error } or { message: { clientEvent: { userAction | error } } }',
        },
      });
    }

    try {
      validateClientEventMessage(event);
      logger.info(
        { eventType: 'userAction' in event ? 'userAction' : 'error' },
        'A2A action: extracted client event'
      );
      await handleClientEvent(event as ClientEventMessage, reply);
    } catch (error) {
      logger.error(
        { error: error instanceof Error ? error.message : 'Unknown error' },
        'A2A action: validation or handling failed'
      );
      if (!reply.sent) {
        reply.code(400).send({
          error: {
            message: error instanceof Error ? error.message : 'Invalid client event',
          },
        });
      }
    }
  });
};
