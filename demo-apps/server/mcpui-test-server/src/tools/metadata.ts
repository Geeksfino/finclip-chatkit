import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { createUIResource } from '@mcp-ui/server';
import { logger } from '../utils/logger.js';

export function registerMetadataTools(server: McpServer): void {
  // Tool 1: Show with Preferred Size
  server.registerTool(
    'showWithPreferredSize',
    {
      title: 'Show with Preferred Size',
      description: 'Demonstrates preferred-frame-size metadata',
      inputSchema: {},
    },
    async () => {
      logger.info({ tool: 'showWithPreferredSize' }, 'Tool called');

      const htmlString = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: system-ui;
      padding: 20px;
      margin: 0;
      background: #f0f0f0;
    }
    .box {
      background: white;
      padding: 20px;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
  </style>
</head>
<body>
  <div class="box">
    <h2>Preferred Size Demo</h2>
    <p>This UI resource has a preferred frame size of 400x300 pixels set via metadata.</p>
    <p>The native client should apply this size automatically.</p>
  </div>
  <script>
    if (window.mcpUI) window.mcpUI.reportSize();
  </script>
</body>
</html>
      `;

      const uiResource = createUIResource({
        uri: 'ui://metadata/preferred-size',
        content: { type: 'rawHtml', htmlString },
        encoding: 'text',
        uiMetadata: {
          'preferred-frame-size': ['400', '300'],
        },
      });

      return { content: [uiResource] };
    }
  );

  // Tool 2: Show with Render Data
  server.registerTool(
    'showWithRenderData',
    {
      title: 'Show with Render Data',
      description: 'Demonstrates initial-render-data metadata',
      inputSchema: {},
    },
    async () => {
      logger.info({ tool: 'showWithRenderData' }, 'Tool called');

      const htmlString = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: system-ui;
      padding: 20px;
      margin: 0;
    }
    .info {
      background: #e3f2fd;
      padding: 15px;
      border-radius: 8px;
      margin-bottom: 15px;
    }
    pre {
      background: #f5f5f5;
      padding: 10px;
      border-radius: 4px;
      overflow-x: auto;
    }
  </style>
</head>
<body>
  <h2>Render Data Demo</h2>
  <div class="info">
    <strong>Render data is available via window.mcpUIRenderData</strong>
  </div>
  <div id="data"></div>
  
  <script>
    const dataDiv = document.getElementById('data');
    if (window.mcpUIRenderData) {
      dataDiv.innerHTML = '<h3>Received Render Data:</h3><pre>' + 
        JSON.stringify(window.mcpUIRenderData, null, 2) + '</pre>';
    } else {
      dataDiv.innerHTML = '<p>No render data available</p>';
    }
    
    if (window.mcpUI) window.mcpUI.reportSize();
  </script>
</body>
</html>
      `;

      const uiResource = createUIResource({
        uri: 'ui://metadata/render-data',
        content: { type: 'rawHtml', htmlString },
        encoding: 'text',
        uiMetadata: {
          'initial-render-data': {
            userId: 'test-user-123',
            theme: 'light',
            timestamp: new Date().toISOString(),
            serverVersion: '1.0.0',
          },
        },
      });

      return { content: [uiResource] };
    }
  );

  logger.info('✅ Metadata tools registered (2 tools)');
}
