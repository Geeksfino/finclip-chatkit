# agui-test-server Testing

## Test Coverage Overview

| Test File | Description | Count |
|-----------|-------------|-------|
| `validation.test.ts` | RunAgentInput validation, runId generation | 7 |
| `agents.test.ts` | EchoAgent basic behavior | 2 |
| `a2ui.test.ts` | A2UI utils, proxy, A2UIAgent | 15 |
| `mcp-integration.test.ts` | MCP client (agui as MCP consumer), tool conversion, LLM MCP tool execution | 9 |
| `llm-agent-logging.test.ts` | LLM error logging details | 2 |

## A2UI Tests (a2ui.test.ts)

- **extractA2UIForwardedProps**: null/undefined, a2uiClientCapabilities, surfaceId branches
- **createA2UICustomEvent**: CUSTOM event structure and payload format
- **streamA2UIPayloads**: JSONL parsing, A2UIPayloadWire mapping, error response handling
- **A2UIAgent**: Event sequence, last user message, forwardedProps passing, RUN_ERROR on proxy failure

## MCP Integration Tests (mcp-integration.test.ts)

Tests agui-test-server as MCP **client** (consumer of mcpui-test-server):

- **MCPClientManager**: connect, getToolsAsOpenAIFormat, callTool, exception when disconnected
- **GENERATE_A2UI_TOOL**: Tool name and parameter validation
- **LLMAgent + MCP**: TOOL_CALL_RESULT and CUSTOM (mcp-ui-resource) events after MCP tool call

> mcpui-test-server's own tests live in `mcpui-test-server/tests/`.

## Optional Improvements

1. **ScenarioAgent**: Add ScenarioAgent scenario matching and event sequence tests (EchoAgent already covered)
2. **LLMAgent streaming**: Add pure streaming (no tools) path tests for chunk order and TEXT_MESSAGE_* lifecycle
3. **agent-factory**: Add agent type selection logic tests for different configs (requires mock config)
4. **Route layer**: Add `/agent`, `/health` request/response and SSE stream format tests
5. **mcpui-test-server**: Now has `tests/health.test.ts` and `tests/tools.test.ts`; optional: MCP protocol response integration tests
