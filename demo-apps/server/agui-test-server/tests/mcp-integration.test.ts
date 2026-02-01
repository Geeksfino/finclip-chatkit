/**
 * MCP Integration Tests (agui-test-server as MCP client)
 * Covers: MCPClientManager (tool format conversion, callTool), LLMAgent MCP tool execution.
 * These tests belong to agui-test-server - they verify agui's integration with MCP protocol.
 * For mcpui-test-server's own tests, see mcpui-test-server/tests/.
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { EventType } from '@ag-ui/core';
import { MCPClientManager } from '../src/mcp/client.js';
import { LLMAgent, GENERATE_A2UI_TOOL } from '../src/agents/llm.js';
import type { RunAgentInput } from '@ag-ui/core';
import { CUSTOM_EVENT_NAMES, A2UI_CONSTANTS } from '../src/constants.js';

const MOCK_MCP_TOOLS = [
  {
    name: 'showSimpleHtml',
    description: 'Displays basic HTML content',
    inputSchema: {
      type: 'object',
      properties: { message: { type: 'string' } },
    },
  },
  {
    name: 'showInteractiveForm',
    description: 'Shows an interactive form',
    inputSchema: { type: 'object' },
  },
];

const mockClientInstance = vi.hoisted(() => ({
  connect: vi.fn(async () => {}),
  listTools: vi.fn(async () => ({ tools: MOCK_MCP_TOOLS })),
  callTool: vi.fn(async () => ({
    content: [
      { type: 'text' as const, text: 'HTML displayed' },
      { type: 'resource' as const, resource: { uri: 'ui://simple-html/1', mimeType: 'text/html' } },
    ],
  })),
  close: vi.fn(async () => {}),
}));

vi.mock('@modelcontextprotocol/sdk/client/index.js', () => ({
  Client: vi.fn().mockImplementation(() => mockClientInstance),
}));

vi.mock('../src/mcp/http-transport.js', () => ({
  HTTPClientTransport: vi.fn().mockImplementation(() => ({
    start: vi.fn(),
    send: vi.fn(),
    close: vi.fn(),
  })),
}));

describe('MCPClientManager', () => {
  let manager: MCPClientManager;

  beforeEach(() => {
    vi.clearAllMocks();
    mockClientInstance.listTools.mockResolvedValue({ tools: MOCK_MCP_TOOLS });
    manager = new MCPClientManager();
  });

  it('should connect and load tools', async () => {
    await manager.connect('mcp-test', {
      url: 'http://localhost:3000/mcp',
      timeout: 5000,
    });

    expect(manager.isConnected('mcp-test')).toBe(true);
    expect(mockClientInstance.connect).toHaveBeenCalled();
    expect(mockClientInstance.listTools).toHaveBeenCalled();
  });

  it('should convert MCP tools to OpenAI format', async () => {
    await manager.connect('mcp-test', { url: 'http://localhost:3000/mcp' });

    const openaiTools = manager.getToolsAsOpenAIFormat('mcp-test');

    expect(openaiTools.length).toBe(2);
    expect(openaiTools[0]).toMatchObject({
      type: 'function',
      function: {
        name: 'showSimpleHtml',
        description: 'Displays basic HTML content',
        parameters: { type: 'object', properties: { message: { type: 'string' } } },
      },
    });
    expect(openaiTools[1].function.name).toBe('showInteractiveForm');
  });

  it('should use fallback description when missing', async () => {
    mockClientInstance.listTools.mockResolvedValueOnce({
      tools: [{ name: 'noDescTool', inputSchema: {} }],
    });
    await manager.connect('other', { url: 'http://localhost:3000/mcp' });

    const openaiTools = manager.getToolsAsOpenAIFormat('other');
    expect(openaiTools[0].function.description).toBe('Tool: noDescTool');
  });

  it('should call tool and return parsed result', async () => {
    await manager.connect('mcp-test', { url: 'http://localhost:3000/mcp' });

    const result = await manager.callTool('mcp-test', 'showSimpleHtml', { message: 'Hi' });

    expect(result.content).toBeDefined();
    const textPart = result.content?.find((c) => c.type === 'text');
    expect(textPart?.type).toBe('text');
    expect((textPart as { type: 'text'; text?: string }).text).toBe('HTML displayed');
    const resourcePart = result.content?.find((c) => c.type === 'resource');
    expect(resourcePart?.type).toBe('resource');
    expect((resourcePart as { type: 'resource'; resource?: { uri: string } }).resource?.uri).toBe('ui://simple-html/1');
  });

  it('should throw when calling tool on disconnected server', async () => {
    await expect(
      manager.callTool('unknown-server', 'showSimpleHtml', {})
    ).rejects.toThrow(/MCP client not connected/);
  });

  it('should return empty array for unknown server getToolsAsOpenAIFormat', () => {
    expect(manager.getToolsAsOpenAIFormat('unknown')).toEqual([]);
  });
});

describe('GENERATE_A2UI_TOOL', () => {
  it('should have correct tool name', () => {
    expect(GENERATE_A2UI_TOOL.function.name).toBe(A2UI_CONSTANTS.TOOL_NAME);
  });

  it('should have required message parameter', () => {
    expect(GENERATE_A2UI_TOOL.function.parameters?.required).toContain('message');
  });
});

const mockUndiciFetch = vi.hoisted(() => vi.fn());

vi.mock('undici', () => ({
  fetch: (...args: unknown[]) => mockUndiciFetch(...args),
}));

describe('LLMAgent with MCP integration', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should emit TOOL_CALL_RESULT and CUSTOM (mcp-ui-resource) when MCP tool is called', async () => {
    const executeTool = vi.fn().mockResolvedValue({
      textContent: 'HTML displayed',
      uiResources: [{ uri: 'ui://simple-html/1', mimeType: 'text/html' }],
    });

    mockUndiciFetch.mockImplementation(() => {
        const sseChunks = [
          JSON.stringify({
            choices: [{
              delta: { tool_calls: [{ id: 'tc-1', function: { name: 'showSimpleHtml', arguments: '{"message":"Hi"}' } }] },
            }],
          }),
          JSON.stringify({ choices: [{ delta: {}, finish_reason: 'tool_calls' }] }),
        ];

        let idx = 0;
        const stream = new ReadableStream({
          pull(controller) {
            if (idx < sseChunks.length) {
              controller.enqueue(new TextEncoder().encode(`data: ${sseChunks[idx]}\n`));
              idx++;
            } else {
              controller.close();
            }
          },
        });

        return Promise.resolve(
          new Response(stream, {
            headers: { 'Content-Type': 'text/event-stream' },
          })
        );
      });

    const agent = new LLMAgent(
      {
        endpoint: 'https://api.example.com/v1',
        apiKey: 'test-key',
        model: 'gpt-4',
        maxRetries: 0,
        timeoutMs: 5000,
      },
      {
        serverId: 'mcp-test',
        tools: [{
          type: 'function',
          function: { name: 'showSimpleHtml', description: 'Show HTML', parameters: {} },
        }],
        toolCallTimeoutMs: 5000,
        executeTool,
      },
      undefined
    );

    const input: RunAgentInput = {
      threadId: 't1',
      runId: 'r1',
      messages: [{ id: 'm1', role: 'user', content: 'Show me HTML' }],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: { type: string; name?: string; content?: string; value?: unknown }[] = [];
    for await (const e of agent.run(input)) {
      events.push({
        type: e.type,
        name: (e as { name?: string }).name,
        content: (e as { content?: string }).content,
        value: (e as { value?: unknown }).value,
      });
    }

    expect(executeTool).toHaveBeenCalledWith('showSimpleHtml', { message: 'Hi' });

    const toolResult = events.find((e) => e.type === EventType.TOOL_CALL_RESULT);
    expect(toolResult).toBeDefined();
    expect(toolResult?.content).toBe('HTML displayed');

    const customEvents = events.filter(
      (e) => e.type === EventType.CUSTOM && e.name === CUSTOM_EVENT_NAMES.MCP_UI_RESOURCE
    );
    expect(customEvents.length).toBe(1);
    const customEvt = customEvents[0] as { value?: { uri?: string } };
    expect(customEvt?.value?.uri).toBe('ui://simple-html/1');
  });
});
