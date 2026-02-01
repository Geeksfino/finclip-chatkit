# AG-UI Test Server

A production-grade AG-UI protocol test server for NeuronKit SDK integration testing. Supports multiple agent types including pre-scripted scenarios, echo testing, and real LLM integration via LiteLLM or DeepSeek.

## Features

- ✅ **Full AG-UI Protocol Support** - Implements the complete AG-UI specification
- 🎭 **Multiple Agent Types** - Scenario, Echo, LLM (multi-provider)
- 📡 **SSE Streaming** - Server-Sent Events with proper event encoding
- 🧪 **Test Scenarios** - Pre-built scenarios for deterministic testing
- 🔌 **LLM Integration** - DeepSeek, OpenAI, SiliconFlow, LiteLLM
- 🔗 **Extension Modes** - MCPUI (tools) and A2UI (declarative UI) support
- 🚀 **High Performance** - Built on Fastify
- 🔍 **Structured Logging** - Pino-based logging

## Quick Start

### Prerequisites

- Node.js 20+
- npm/yarn/pnpm

### Installation

```bash
cd agui-test-server
npm install
```

### Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Key configuration options (see `.env.example` for full list):

```env
# Server
PORT=3000
HOST=0.0.0.0

# Agent mode: emulated | llm
AGENT_MODE=emulated
DEFAULT_SCENARIO=tool-call     # When emulated: echo | simple-chat | tool-call | error-handling

# LLM (when AGENT_MODE=llm)
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
LLM_API_KEY=your-key

# Extensions: none | mcpui | a2ui
EXTENSION_MODE=none
MCPUI_SERVER_URL=http://localhost:3100/mcp
A2UI_SERVER_URL=http://localhost:3200
```

### Running the Server

**Development mode** (with hot reload):
```bash
npm run dev
```

**Production mode**:
```bash
npm run build
npm start
```

The server will start on `http://localhost:3000`.

## API Endpoints

### POST /agent

Main AG-UI endpoint. Accepts `RunAgentInput` and returns SSE stream.

**Request**:
```json
{
  "threadId": "uuid",
  "runId": "run_timestamp_random",
  "messages": [
    {
      "id": "msg-uuid",
      "role": "user",
      "content": "Hello"
    }
  ],
  "tools": [],
  "context": [],
  "state": null,
  "forwardedProps": null
}
```

**Response**: `text/event-stream`

```
event: message
data: {"type":"RUN_STARTED","threadId":"...","runId":"..."}

event: message
data: {"type":"TEXT_MESSAGE_CHUNK","messageId":"...","delta":"Hello"}

event: message
data: {"type":"RUN_FINISHED","threadId":"...","runId":"..."}
```

### GET /scenarios

List all available test scenarios.

**Response**:
```json
{
  "scenarios": [
    {
      "id": "simple-chat",
      "name": "Simple Chat",
      "description": "Basic conversation with greeting",
      "turnCount": 2
    }
  ]
}
```

### POST /scenarios/:id

Run a specific scenario directly (useful for testing).

**Request**:
```json
{
  "threadId": "test-123",
  "messages": [
    {
      "id": "msg-1",
      "role": "user",
      "content": "hello"
    }
  ]
}
```

### GET /health

Health check endpoint.

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-10-01T06:00:00.000Z",
  "uptime": 123.45,
  "sessions": 5
}
```

## Agent Types

### Scenario Agent (Emulated - Default)

Pre-scripted responses. Set `AGENT_MODE=emulated` and `DEFAULT_SCENARIO=<id>`:
- `simple-chat` - Basic conversation
- `tool-call` - Tool invocation demo
- `error-handling` - Error scenarios

### Echo Agent

Set `AGENT_MODE=emulated` and `DEFAULT_SCENARIO=echo`.

### LLM Agent

Real AI via `AGENT_MODE=llm` and `LLM_PROVIDER`/`LLM_MODEL`/`LLM_API_KEY`. Supported: `deepseek`, `openai`, `siliconflow`, `litellm`.

### Extension Modes

- **MCPUI** (`EXTENSION_MODE=mcpui`): LLM can call tools from mcpui-test-server. Start mcpui-test-server on port 3100.
- **A2UI** (`EXTENSION_MODE=a2ui`): Emitted mode proxies to a2ui-test-server; LLM mode uses intent-driven `generateA2UI` tool. Start a2ui-test-server on port 3200.

## Testing with NeuronKit

### Swift Integration

```swift
import NeuronKit

let config = NeuronKitConfig(
    serverURL: URL(string: "http://localhost:3000/agent")!,
    deviceId: "test-device",
    userId: "test-user",
    storage: .inMemory
)

let runtime = NeuronRuntime(config: config)
let conversation = runtime.openConversation(agentId: UUID())

// Send message
try await conversation.sendMessage("Hello!")

// Bind UI
conversation.bindUI(myUIAdapter)
```

### cURL Testing

```bash
# Simple chat
curl -X POST http://localhost:3000/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1",
    "messages": [{"id":"1","role":"user","content":"hello"}],
    "tools": [],
    "context": []
  }'

# With tool definition
curl -X POST http://localhost:3000/agent \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-456",
    "runId": "run_2",
    "messages": [{"id":"2","role":"user","content":"take a photo"}],
    "tools": [{
      "name": "camera.capture",
      "description": "Capture photo",
      "parameters": {
        "mode": {"type": "string", "required": true}
      }
    }],
    "context": []
  }'
```

## Development

### Project Structure

```
agui-test-server/
├── src/
│   ├── agents/          # Scenario, Echo, A2UI, LLM
│   ├── a2ui/            # A2UI proxy (streamA2UIPayloads)
│   ├── mcp/             # MCP client for MCPUI tools
│   ├── routes/
│   ├── scenarios/
│   ├── streaming/
│   ├── types/
│   └── utils/
├── docs/                # architecture, agui-compliance, resilience
├── tests/
└── package.json
```

### Adding Custom Scenarios

Create a new JSON file in `src/scenarios/`:

```json
{
  "id": "my-scenario",
  "name": "My Custom Scenario",
  "description": "Description here",
  "turns": [
    {
      "trigger": {
        "userMessage": ".*keyword.*"
      },
      "events": [
        {
          "type": "TEXT_MESSAGE_CHUNK",
          "messageId": "msg_1",
          "delta": "Response text"
        }
      ],
      "delayMs": 200
    }
  ]
}
```

Register in `src/scenarios/index.ts`:

```typescript
scenarios['my-scenario'] = loadScenario('my-scenario.json');
```

### Running Tests

```bash
npm test           # Run tests
npm run test:ui    # Run tests with UI
```

### Linting

```bash
npm run lint       # Check code
npm run format     # Format code
```

## Deployment

### Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t agui-test-server .
docker run -p 3000:3000 --env-file .env agui-test-server
```

### Environment Variables

See `.env.example` for all available configuration options.

## Troubleshooting

### Connection Issues

- Verify server is running: `curl http://localhost:3000/health`
- Check firewall settings
- Ensure NeuronKit is pointing to correct URL

### SSE Stream Issues

- Check `Accept: text/event-stream` header
- Verify no proxies are buffering the response
- Check server logs for errors

### LLM Integration Issues

- Verify LiteLLM proxy is running
- Check API keys are correct
- Review logs for API errors

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## License

MIT

## Related Projects

- [NeuronKit](../neuronkit) - Swift SDK for AG-UI
- [AG-UI Protocol](https://docs.ag-ui.com) - Official specification
- [LiteLLM](https://github.com/BerriAI/litellm) - LLM proxy
