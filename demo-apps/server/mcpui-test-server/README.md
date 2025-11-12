# MCP-UI Test Server

A comprehensive MCP-UI protocol test server for ConvoUI-iOS integration testing. Implements the Model Context Protocol (MCP) with full MCP-UI support.

## Features

- ✅ **Full MCP Protocol** - Implements complete MCP specification
- 🎨 **11 UI Resource Tools** - Covering all MCP-UI scenarios
- 📡 **HTTP Streaming** - StreamableHTTPServerTransport
- 🔧 **3 Content Types** - HTML, External URLs, Remote DOM
- 📊 **Metadata Support** - Preferred size, render data
- 🔄 **Async Protocol** - Message IDs, acknowledgments, responses
- 🚀 **High Performance** - Built on Express
- 📝 **Structured Logging** - Pino-based logging

## Quick Start

### Prerequisites

- Node.js 20+
- npm/yarn/pnpm

### Installation

```bash
cd mcpui-test-server
npm install
```

### Configuration

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Configuration options:

```env
PORT=3100
HOST=0.0.0.0
NODE_ENV=development
SERVER_NAME=mcpui-test-server
SERVER_VERSION=1.0.0
LOG_LEVEL=info
LOG_PRETTY=true
CORS_ORIGIN=*
SESSION_TIMEOUT=3600000
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

The server will start on `http://localhost:3100`.

## API Endpoints

### MCP Protocol Endpoints

- `POST /mcp` - Client-to-server communication
- `GET /mcp` - Server-to-client stream
- `DELETE /mcp` - Session termination

### Utility Endpoints

- `GET /health` - Health check
- `GET /tools` - List all available tools

## Available Tools

### HTML Content Tools (3)

1. **showSimpleHtml** - Basic HTML with styling and interactive buttons
2. **showInteractiveForm** - Form with validation and async submission
3. **showComplexLayout** - Multi-column responsive layout

### External URL Tools (3)

4. **showExampleSite** - Displays example.com
5. **showCustomUrl** - Displays user-provided URL
6. **showApiDocs** - Displays MCP-UI documentation

### Remote DOM Tools (2)

7. **showRemoteDomButton** - Interactive button with counter
8. **showRemoteDomForm** - Form with validation

### Metadata Tools (2)

9. **showWithPreferredSize** - Demonstrates preferred-frame-size
10. **showWithRenderData** - Demonstrates initial-render-data

### Async Protocol Tools (1)

11. **showAsyncToolCall** - Demonstrates async message protocol

## Testing with ConvoUI-iOS

### Swift Integration

```swift
import ConvoUI

let mcpClient = MCPClient(serverURL: URL(string: "http://localhost:3100")!)

// Initialize connection
try await mcpClient.initialize()

// List tools
let tools = try await mcpClient.listTools()

// Call a tool
let result = try await mcpClient.callTool(name: "showSimpleHtml", parameters: [:])

// Display UI resource
if let resource = result.content.first {
    let message = FinConvoMCPUIMessageModel.messageFromMCPResource(
        resource,
        messageId: UUID().uuidString,
        timestamp: Date()
    )
    resourceView.loadResource(message)
}
```

### cURL Testing

```bash
# Initialize session
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "test", "version": "1.0.0"}
    }
  }'

# List tools
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -H "mcp-session-id: <session-id>" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'

# Call a tool
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -H "mcp-session-id: <session-id>" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "showSimpleHtml",
      "arguments": {}
    }
  }'
```

## Development

### Project Structure

```
mcpui-test-server/
├── src/
│   ├── server.ts           # Main Express server
│   ├── mcp/
│   │   └── session.ts      # Session management
│   ├── tools/
│   │   ├── index.ts        # Tool registry
│   │   ├── html.ts         # HTML tools
│   │   ├── url.ts          # URL tools
│   │   ├── remote-dom.ts   # Remote DOM tools
│   │   ├── metadata.ts     # Metadata tools
│   │   └── async.ts        # Async protocol tools
│   ├── types/
│   │   └── index.ts        # TypeScript types
│   └── utils/
│       └── logger.ts       # Logging utilities
├── tests/
├── package.json
├── tsconfig.json
└── README.md
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
EXPOSE 3100
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t mcpui-test-server .
docker run -p 3100:3100 --env-file .env mcpui-test-server
```

## Troubleshooting

### Connection Issues

- Verify server is running: `curl http://localhost:3100/health`
- Check firewall settings
- Ensure client is pointing to correct URL

### Session Issues

- Sessions expire after 1 hour by default
- Check `SESSION_TIMEOUT` in `.env`
- Monitor session count via `/health` endpoint

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Submit a pull request

## License

MIT

## Related Projects

- [ConvoUI-iOS](../ConvoUI-iOS) - Native iOS MCP-UI client
- [MCP Protocol](https://modelcontextprotocol.io/) - Official specification
- [@mcp-ui/server](https://www.npmjs.com/package/@mcp-ui/server) - MCP-UI server SDK
