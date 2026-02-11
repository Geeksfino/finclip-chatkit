/**
 * MCP Client Manager
 */

import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { HTTPClientTransport } from './http-transport.js';
import { PACKAGE_NAME, PACKAGE_VERSION } from '../constants.js';
import { logger } from '../utils/logger.js';
import { getErrorMessage } from '../utils/helpers.js';
import type {
  MCPClientConfig,
  MCPTool,
  MCPToolCallResult,
  OpenAITool,
} from './types.js';

export class MCPClientManager {
  private clients: Map<string, Client> = new Map();
  private toolsCache: Map<string, MCPTool[]> = new Map();

  async connect(serverId: string, config: MCPClientConfig): Promise<void> {
    if (this.clients.has(serverId)) {
      return;
    }

    try {
      const transport = new HTTPClientTransport({
        url: config.url,
        headers: config.headers,
        timeout: config.timeout,
      });

      const client = new Client(
        { name: PACKAGE_NAME, version: PACKAGE_VERSION },
        { capabilities: {} }
      );

      await client.connect(transport);
      this.clients.set(serverId, client);
      logger.info({ serverId, url: config.url }, 'MCP client connected');

      await this.refreshTools(serverId);
    } catch (error) {
      logger.error(
        { serverId, error: getErrorMessage(error) },
        'Failed to connect to MCP server'
      );
      throw error;
    }
  }

  async refreshTools(serverId: string): Promise<MCPTool[]> {
    const client = this.clients.get(serverId);
    if (!client) {
      throw new Error(`MCP client not connected: ${serverId}`);
    }

    const result = await client.listTools();
    const tools = (result.tools || []) as MCPTool[];
    this.toolsCache.set(serverId, tools);
    logger.info({ serverId, toolCount: tools.length }, 'MCP tools loaded');
    return tools;
  }

  getTools(serverId: string): MCPTool[] {
    return this.toolsCache.get(serverId) || [];
  }

  getToolsAsOpenAIFormat(serverId: string): OpenAITool[] {
    const tools = this.toolsCache.get(serverId) || [];
    return tools.map((tool) => {
      const desc = tool.description || `Tool: ${tool.name}`;
      const withTitle =
        tool.title && !desc.startsWith(tool.title) ? `${tool.title}。${desc}` : desc;
      return {
        type: 'function' as const,
        function: {
          name: tool.name,
          description: withTitle,
          parameters: tool.inputSchema || {},
        },
      };
    });
  }

  async callTool(
    serverId: string,
    toolName: string,
    args: Record<string, unknown>
  ): Promise<MCPToolCallResult> {
    const client = this.clients.get(serverId);
    if (!client) {
      throw new Error(`MCP client not connected: ${serverId}`);
    }

    const result = await client.callTool({
      name: toolName,
      arguments: args,
    });

    return result as MCPToolCallResult;
  }

  isConnected(serverId: string): boolean {
    return this.clients.has(serverId);
  }

  async disconnect(serverId: string): Promise<void> {
    const client = this.clients.get(serverId);
    if (!client) return;

    try {
      await client.close();
      this.clients.delete(serverId);
      this.toolsCache.delete(serverId);
    } catch (error) {
      logger.error({ serverId }, 'Error disconnecting MCP client');
    }
  }
}

export const mcpClientManager = new MCPClientManager();
