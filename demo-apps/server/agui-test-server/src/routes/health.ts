/**
 * Health Check Endpoint
 */

import type { FastifyPluginAsync } from 'fastify';
import { sessionManager } from '../streaming/session.js';
import { sseConnectionManager } from '../streaming/connection.js';
import { loadConfig } from '../utils/config.js';
import { mcpClientManager } from '../mcp/index.js';

export const healthRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/health', async (_request, _reply) => {
    const config = loadConfig();
    const mcpStatus =
      config.extensionMode === 'mcpui'
        ? {
            enabled: true,
            connected: mcpClientManager.isConnected(config.mcp.serverId),
            serverUrl: config.mcp.serverUrl,
            toolCount: mcpClientManager.getTools(config.mcp.serverId).length,
          }
        : { enabled: false };
    const a2uiStatus =
      config.extensionMode === 'a2ui'
        ? { enabled: true, serverUrl: config.a2ui.serverUrl }
        : { enabled: false };

    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      sessions: sessionManager.size,
      sseConnections: sseConnectionManager.size,
      mcp: mcpStatus,
      a2ui: a2uiStatus,
    };
  });
};
