import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerHTMLTools } from './html.js';
import { registerURLTools } from './url.js';
import { registerRemoteDOMTools } from './remote-dom.js';
import { registerMetadataTools } from './metadata.js';
import { registerAsyncTools } from './async.js';
import { logger } from '../utils/logger.js';

export function registerTools(server: McpServer): void {
  logger.info('Registering MCP-UI tools...');
  
  // Register all tool categories
  registerHTMLTools(server);
  registerURLTools(server);
  registerRemoteDOMTools(server);
  registerMetadataTools(server);
  registerAsyncTools(server);
  
  logger.info('✅ All tools registered successfully');
}
