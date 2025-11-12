import { z } from 'zod';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { createUIResource } from '@mcp-ui/server';
import { logger } from '../utils/logger.js';

const simpleHtmlInputSchema = {
  message: z.string().describe('Custom message to display').optional(),
};

const emptyInputSchema = {};

export function registerHTMLTools(server: McpServer): void {
  // Tool 1: Simple HTML
  server.registerTool(
    'showSimpleHtml',
    {
      title: 'Show Simple HTML',
      description: 'Displays basic HTML content with styling and interactive buttons',
      inputSchema: simpleHtmlInputSchema,
    },
    async (params: unknown) => {
      const { message = 'Hello from MCP-UI Test Server!' } = z.object(simpleHtmlInputSchema).parse(params);
      logger.info({ tool: 'showSimpleHtml', message }, 'Tool called');

      const htmlString = `
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      padding: 20px;
      margin: 0;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .card {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      border-radius: 12px;
      padding: 24px;
      margin: 16px 0;
      box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
    }
    h1 {
      margin: 0 0 16px 0;
      font-size: 24px;
    }
    p {
      margin: 0 0 20px 0;
      line-height: 1.6;
    }
    .actions {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
    }
    button {
      background: white;
      color: #667eea;
      border: none;
      padding: 12px 24px;
      border-radius: 8px;
      font-weight: 600;
      cursor: pointer;
      transition: transform 0.2s;
    }
    button:hover {
      transform: scale(1.05);
    }
    button:active {
      transform: scale(0.95);
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>${message}</h1>
    <p>This is a simple HTML UI resource from the MCP-UI test server. Click the buttons below to test different action types.</p>
    <div class="actions">
      <button onclick="window.mcpUI.callTool('echo', {text: 'Hello'}, 'msg-1')">
        Call Tool
      </button>
      <button onclick="window.mcpUI.triggerIntent('refresh', {}, 'msg-2')">
        Trigger Intent
      </button>
      <button onclick="window.mcpUI.submitPrompt('Tell me more about MCP-UI')">
        Submit Prompt
      </button>
      <button onclick="window.mcpUI.notify('Button clicked!')">
        Show Notification
      </button>
    </div>
  </div>
  <script>
    // Report size for auto-resize
    if (window.mcpUI && window.mcpUI.reportSize) {
      setTimeout(() => window.mcpUI.reportSize(), 100);
    }
    
    // Log render data if available
    if (window.mcpUIRenderData) {
      console.log('Render data:', window.mcpUIRenderData);
    }
  </script>
</body>
</html>
      `;

      try {
        const uiResource = createUIResource({
          uri: 'ui://simple-html/1',
          content: { type: 'rawHtml', htmlString },
          encoding: 'text',
        });

        return { content: [uiResource] };
      } catch (error) {
        logger.error({ error, htmlLength: htmlString.length }, 'Failed to create UI resource for showSimpleHtml');
        throw error;
      }
    }
  );

  // Tool 1a: Raw HTML demo (baseline example)
  server.registerTool(
    'showRawHtml',
    {
      title: 'Show Raw HTML',
      description: 'Minimal raw HTML sample similar to MCP-UI reference demo',
      inputSchema: emptyInputSchema,
    },
    async (params) => {
      z.object(emptyInputSchema).parse(params);
      logger.info({ tool: 'showRawHtml' }, 'Tool called');

      const uiResource = createUIResource({
        uri: 'ui://raw-html-demo',
        content: { type: 'rawHtml', htmlString: '<h1>Hello from Raw HTML</h1>' },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 2: Interactive Form
  server.registerTool(
    'showInteractiveForm',
    {
      title: 'Show Interactive Form',
      description: 'Displays an interactive form with validation and async submission',
      inputSchema: emptyInputSchema,
    },
    async (params: unknown) => {
      z.object(emptyInputSchema).parse(params);
      logger.info({ tool: 'showInteractiveForm' }, 'Tool called');

      const formHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: system-ui, -apple-system, sans-serif;
      padding: 20px;
      max-width: 400px;
      margin: 0 auto;
      background: #f5f5f7;
    }
    h2 {
      color: #1d1d1f;
      margin: 0 0 20px 0;
    }
    .form-group {
      margin-bottom: 16px;
    }
    label {
      display: block;
      margin-bottom: 8px;
      font-weight: 600;
      color: #1d1d1f;
    }
    input, textarea {
      width: 100%;
      padding: 12px;
      border: 1px solid #d2d2d7;
      border-radius: 8px;
      font-size: 14px;
      box-sizing: border-box;
    }
    input:focus, textarea:focus {
      outline: none;
      border-color: #007AFF;
    }
    button {
      width: 100%;
      padding: 14px;
      background: #007AFF;
      color: white;
      border: none;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
    }
    button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
    .status {
      margin-top: 16px;
      padding: 12px;
      border-radius: 8px;
      display: none;
    }
    .status.success {
      background: #d4edda;
      color: #155724;
      display: block;
    }
    .status.error {
      background: #f8d7da;
      color: #721c24;
      display: block;
    }
  </style>
</head>
<body>
  <h2>Contact Form</h2>
  <form id="contactForm">
    <div class="form-group">
      <label for="name">Name *</label>
      <input type="text" id="name" required />
    </div>
    <div class="form-group">
      <label for="email">Email *</label>
      <input type="email" id="email" required />
    </div>
    <div class="form-group">
      <label for="message">Message *</label>
      <textarea id="message" rows="4" required></textarea>
    </div>
    <button type="submit" id="submitBtn">Submit</button>
  </form>
  <div id="status" class="status"></div>
  
  <script>
    const form = document.getElementById('contactForm');
    const status = document.getElementById('status');
    const submitBtn = document.getElementById('submitBtn');
    
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const formData = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        message: document.getElementById('message').value,
        timestamp: new Date().toISOString()
      };
      
      // Disable button during submission
      submitBtn.disabled = true;
      submitBtn.textContent = 'Submitting...';
      
      // Call MCP tool with async message ID
      const messageId = 'form-submit-' + Date.now();
      window.mcpUI.callTool('processContactForm', formData, messageId);
      
      // Listen for response
      window.addEventListener('message', (event) => {
        if (event.data.type === 'ui-message-response' && 
            event.data.messageId === messageId) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Submit';
          
          if (event.data.payload && !event.data.payload.error) {
            status.className = 'status success';
            status.textContent = 'Form submitted successfully!';
            form.reset();
          } else {
            status.className = 'status error';
            status.textContent = 'Error: ' + (event.data.payload?.error || 'Unknown error');
          }
          
          setTimeout(() => {
            status.style.display = 'none';
          }, 3000);
        }
      });
    });
    
    // Report size
    if (window.mcpUI) {
      window.mcpUI.reportSize();
    }
  </script>
</body>
</html>
      `;

      const uiResource = createUIResource({
        uri: 'ui://interactive-form/1',
        content: { type: 'rawHtml', htmlString: formHtml },
        encoding: 'blob',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 3: Complex Layout
  server.registerTool(
    'showComplexLayout',
    {
      title: 'Show Complex Layout',
      description: 'Displays a multi-column layout with images and styled content',
      inputSchema: emptyInputSchema,
    },
    async (params: unknown) => {
      z.object(emptyInputSchema).parse(params);
      logger.info({ tool: 'showComplexLayout' }, 'Tool called');

      const layoutHtml = `
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: system-ui, sans-serif;
      margin: 0;
      padding: 20px;
      background: #fafafa;
    }
    .container {
      max-width: 800px;
      margin: 0 auto;
    }
    .header {
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      padding: 30px;
      border-radius: 12px;
      margin-bottom: 20px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }
    .card {
      background: white;
      border-radius: 12px;
      padding: 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .card h3 {
      margin: 0 0 10px 0;
      color: #1d1d1f;
    }
    .card p {
      margin: 0;
      color: #666;
      line-height: 1.6;
    }
    .badge {
      display: inline-block;
      padding: 4px 12px;
      background: #007AFF;
      color: white;
      border-radius: 12px;
      font-size: 12px;
      margin-top: 10px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>MCP-UI Dashboard</h1>
      <p>A complex layout demonstration</p>
    </div>
    
    <div class="grid">
      <div class="card">
        <h3>Feature 1</h3>
        <p>This card demonstrates a complex multi-column layout with responsive design.</p>
        <span class="badge">Active</span>
      </div>
      
      <div class="card">
        <h3>Feature 2</h3>
        <p>Cards automatically adjust to screen size using CSS Grid.</p>
        <span class="badge">Beta</span>
      </div>
      
      <div class="card">
        <h3>Feature 3</h3>
        <p>Each card can contain different content types and actions.</p>
        <span class="badge">New</span>
      </div>
    </div>
    
    <div class="card">
      <h3>Actions</h3>
      <p>Click below to test different interactions:</p>
      <button onclick="window.mcpUI.notify('Complex layout loaded!')" 
              style="margin-top: 10px; padding: 10px 20px; background: #007AFF; color: white; border: none; border-radius: 8px; cursor: pointer;">
        Test Notification
      </button>
    </div>
  </div>
  
  <script>
    if (window.mcpUI) {
      window.mcpUI.reportSize();
    }
  </script>
</body>
</html>
      `;

      const uiResource = createUIResource({
        uri: 'ui://complex-layout/1',
        content: { type: 'rawHtml', htmlString: layoutHtml },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  logger.info('✅ HTML tools registered (3 tools)');
}
