import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { createUIResource } from '@mcp-ui/server';
import { logger } from '../utils/logger.js';

export function registerRemoteDOMTools(server: McpServer): void {
  // Tool 1: Remote DOM Button
  server.registerTool(
    'showRemoteDomButton',
    {
      title: 'Show Remote DOM Button',
      description: 'Interactive button using Remote DOM',
      inputSchema: {},
    },
    async () => {
      logger.info({ tool: 'showRemoteDomButton' }, 'Tool called');

      const remoteDomScript = `
// Create button
const button = document.createElement('ui-button');
button.setAttribute('label', 'Click Me!');
button.setAttribute('variant', 'primary');

// Create counter
const counter = document.createElement('ui-text');
let count = 0;
counter.textContent = 'Clicks: 0';

// Handle button press
button.addEventListener('press', () => {
  count++;
  counter.textContent = 'Clicks: ' + count;
  
  // Call MCP tool on every 5th click
  if (count % 5 === 0) {
    window.parent.postMessage({
      type: 'tool',
      payload: {
        toolName: 'recordClicks',
        params: { count }
      },
      messageId: 'click-' + count
    }, '*');
  }
});

// Layout
const container = document.createElement('ui-stack');
container.setAttribute('spacing', '16');
container.appendChild(counter);
container.appendChild(button);

root.appendChild(container);
      `;

      const uiResource = createUIResource({
        uri: 'ui://remote-dom-button/1',
        content: {
          type: 'remoteDom',
          script: remoteDomScript,
          framework: 'react',
        },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  // Tool 2: Remote DOM Form
  server.registerTool(
    'showRemoteDomForm',
    {
      title: 'Show Remote DOM Form',
      description: 'Form with validation using Remote DOM',
      inputSchema: {},
    },
    async () => {
      logger.info({ tool: 'showRemoteDomForm' }, 'Tool called');

      const remoteDomScript = `
const form = document.createElement('ui-stack');
form.setAttribute('spacing', '12');

const nameInput = document.createElement('ui-text-field');
nameInput.setAttribute('label', 'Name');
nameInput.setAttribute('placeholder', 'Enter your name');

const emailInput = document.createElement('ui-text-field');
emailInput.setAttribute('label', 'Email');
emailInput.setAttribute('type', 'email');
emailInput.setAttribute('placeholder', 'Enter your email');

const submitButton = document.createElement('ui-button');
submitButton.setAttribute('label', 'Submit');
submitButton.setAttribute('variant', 'primary');

submitButton.addEventListener('press', () => {
  const name = nameInput.value;
  const email = emailInput.value;
  
  if (name && email) {
    window.parent.postMessage({
      type: 'tool',
      payload: {
        toolName: 'submitForm',
        params: { name, email }
      },
      messageId: 'form-' + Date.now()
    }, '*');
  }
});

form.appendChild(nameInput);
form.appendChild(emailInput);
form.appendChild(submitButton);

root.appendChild(form);
      `;

      const uiResource = createUIResource({
        uri: 'ui://remote-dom-form/1',
        content: {
          type: 'remoteDom',
          script: remoteDomScript,
          framework: 'react',
        },
        encoding: 'text',
      });

      return { content: [uiResource] };
    }
  );

  logger.info('✅ Remote DOM tools registered (2 tools)');
}
