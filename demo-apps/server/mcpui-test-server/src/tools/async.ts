import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { createUIResource } from '@mcp-ui/server';
import { logger } from '../utils/logger.js';

const asyncRequestInputShape = {
  data: z.string().min(1).describe('Payload data to process'),
  timestamp: z.number().int().describe('Client timestamp (ms since epoch)'),
};

export function registerAsyncTools(server: McpServer): void {
  // Tool 1: Async Tool Call
  server.registerTool(
    'showAsyncToolCall',
    {
      title: 'Show Async Tool Call',
      description: 'Demonstrates async message protocol with message IDs',
      inputSchema: {},
    },
    async () => {
      logger.info({ tool: 'showAsyncToolCall' }, 'Tool called');

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
    .container {
      max-width: 500px;
      margin: 0 auto;
    }
    button {
      padding: 12px 24px;
      background: #007AFF;
      color: white;
      border: none;
      border-radius: 8px;
      cursor: pointer;
      font-size: 16px;
      margin: 10px 0;
    }
    .log {
      background: #f5f5f5;
      padding: 15px;
      border-radius: 8px;
      margin-top: 20px;
      max-height: 300px;
      overflow-y: auto;
    }
    .log-entry {
      padding: 8px;
      margin: 4px 0;
      border-left: 3px solid #007AFF;
      background: white;
    }
    .log-entry.ack {
      border-left-color: #34C759;
    }
    .log-entry.response {
      border-left-color: #FF9500;
    }
  </style>
</head>
<body>
  <div class="container">
    <h2>Async Message Protocol</h2>
    <p>Click the button to send a tool call with a message ID and watch the async responses.</p>
    
    <button onclick="sendAsyncToolCall()">Send Async Tool Call</button>
    
    <div class="log" id="log">
      <div class="log-entry">Ready to send messages...</div>
    </div>
  </div>
  
  <script>
    const log = document.getElementById('log');
    
    function addLog(message, type = 'default') {
      const entry = document.createElement('div');
      entry.className = 'log-entry ' + type;
      entry.textContent = new Date().toLocaleTimeString() + ' - ' + message;
      log.appendChild(entry);
      log.scrollTop = log.scrollHeight;
    }
    
    function sendAsyncToolCall() {
      const messageId = 'async-' + Date.now();
      addLog('Sending tool call with messageId: ' + messageId);
      
      // Send tool call
      window.mcpUI.callTool('processAsyncRequest', {
        data: 'test data',
        timestamp: Date.now()
      }, messageId);
      
      // Listen for acknowledgment and response
      window.addEventListener('message', (event) => {
        if (event.data.messageId === messageId) {
          if (event.data.type === 'ui-message-received') {
            addLog('Received acknowledgment', 'ack');
          } else if (event.data.type === 'ui-message-response') {
            addLog('Received response: ' + JSON.stringify(event.data.payload), 'response');
          }
        }
      });
    }
    
    if (window.mcpUI) window.mcpUI.reportSize();
  </script>
</body>
</html>
      `;

      const uiResource = createUIResource({
        uri: 'ui://async/tool-call',
        content: { type: 'rawHtml', htmlString },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 2: Process Async Request
  server.registerTool(
    'processAsyncRequest',
    {
      title: 'Process Async Request',
      description: 'Handles async tool call demo requests and returns processed data',
      inputSchema: asyncRequestInputShape,
    },
    async (params: unknown) => {
      const parsed = z.object(asyncRequestInputShape).parse(params);
      logger.info({ tool: 'processAsyncRequest', ...parsed }, 'Processing async request');

      // Simulate async processing delay
      await new Promise((resolve) => setTimeout(resolve, 1200));

      const responsePayload = {
        status: 'completed',
        processedAt: new Date().toISOString(),
        received: parsed,
      };

      return {
        content: [
          {
            type: 'text',
            text: JSON.stringify(responsePayload),
          },
        ],
      };
    }
  );

  logger.info('✅ Async tools registered (1 tool)');
}
