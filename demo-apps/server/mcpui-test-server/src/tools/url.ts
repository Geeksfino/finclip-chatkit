import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { createUIResource } from '@mcp-ui/server';
import { logger } from '../utils/logger.js';

const customUrlInputSchema = {
  url: z.string().describe('The URL to display (must be https://)'),
};

const emptyInputSchema = {};

export function registerURLTools(server: McpServer): void {
  // Tool 1: Show Example Site
  server.registerTool(
    'showExampleSite',
    {
      title: 'Show Example Site',
      description: 'Displays example.com in an iframe',
      inputSchema: emptyInputSchema,
    },
    async (params: unknown) => {
      z.object(emptyInputSchema).parse(params);
      logger.info({ tool: 'showExampleSite' }, 'Tool called');

      const uiResource = createUIResource({
        uri: 'ui://external-url/example',
        content: { type: 'externalUrl', iframeUrl: 'https://example.com' },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 2: Show Custom URL
  server.registerTool(
    'showCustomUrl',
    {
      title: 'Show Custom URL',
      description: 'Displays a custom URL provided by the user',
      inputSchema: customUrlInputSchema,
    },
    async (params: unknown) => {
      const { url } = z.object(customUrlInputSchema).parse(params);
      logger.info({ tool: 'showCustomUrl', url }, 'Tool called');

      // Validate URL
      if (!url.startsWith('https://')) {
        throw new Error('URL must start with https://');
      }

      const uiResource = createUIResource({
        uri: `ui://external-url/${encodeURIComponent(url)}`,
        content: { type: 'externalUrl', iframeUrl: url },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 3: Show API Documentation
  server.registerTool(
    'showApiDocs',
    {
      title: 'Show API Documentation',
      description: 'Displays MCP-UI documentation',
      inputSchema: emptyInputSchema,
    },
    async (params: unknown) => {
      z.object(emptyInputSchema).parse(params);
      logger.info({ tool: 'showApiDocs' }, 'Tool called');

      const uiResource = createUIResource({
        uri: 'ui://external-url/docs',
        content: { type: 'externalUrl', iframeUrl: 'https://mcpui.dev' },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  logger.info('✅ URL tools registered (3 tools)');
}
