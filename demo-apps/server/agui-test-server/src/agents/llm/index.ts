/**
 * LLM Agent module
 */

import type { OpenAITool } from '../../mcp/types.js';
import { A2UI_CONSTANTS } from '../../constants.js';
import type { MCPIntegration, A2UIIntegration } from './types.js';
import { LLMAgent } from './agent.js';

export { LLMAgent };
export type { MCPIntegration, A2UIIntegration };
export type { LLMConfig } from './types.js';

export const GENERATE_A2UI_TOOL: OpenAITool = {
  type: 'function',
  function: {
    name: A2UI_CONSTANTS.TOOL_NAME,
    description:
      "Generate an interactive user interface (forms, buttons, inputs, cards, lists, etc.) based on the user's request. Use this ONLY when the user explicitly asks for a form, input fields, buttons, a dashboard, or any structured UI component. Do NOT use for simple greetings, general questions, or conversational responses that don't require UI.",
    parameters: {
      type: 'object',
      properties: {
        message: {
          type: 'string',
          description:
            "The user's UI request or intent (e.g., 'contact form', 'login form', 'list of items')",
        },
      },
      required: ['message'],
    },
  },
};
