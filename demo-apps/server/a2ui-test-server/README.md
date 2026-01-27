# A2UI Test Server

A comprehensive A2UI protocol test server for ChatKit SDK integration testing. Implements the A2UI (Agent to UI) Protocol v0.8 with support for scenario-based and LLM-powered UI generation.

## Features

- ✅ **Full A2UI Protocol v0.8** - Implements complete A2UI specification
- 🎭 **Multiple Agent Types** - Scenario-based (pre-scripted) and LLM-powered
- 📡 **SSE JSONL Streaming** - Server-Sent Events with JSON Lines format
- 🎨 **Standard Components** - Text, Button, Row, Column, Card, TextField, DateTimeInput, List
- 📊 **Data Binding** - Full support for data model updates and bindings
- 🔄 **Progressive Rendering** - Stream UI components incrementally
- 🚀 **High Performance** - Built on Fastify for maximum throughput
- 📝 **Structured Logging** - Pino-based logging with pretty output

## Quick Start

### Prerequisites

- Node.js 20+
- npm/yarn/pnpm

### Installation

```bash
cd a2ui-test-server
npm install
# or
pnpm install
```

### Configuration

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Configuration options:

```env
PORT=3200
HOST=0.0.0.0
NODE_ENV=development

# Agent Configuration
DEFAULT_AGENT=scenario  # scenario or llm
SCENARIO_DIR=./src/scenarios
SCENARIO_DELAY_MS=200

# LLM Configuration (for LLM mode)
LLM_PROVIDER=gemini  # gemini or deepseek
GEMINI_API_KEY=your-gemini-api-key
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat

# SSE Configuration
SSE_RETRY_MS=3000
SSE_HEARTBEAT_MS=30000

# Logging
LOG_LEVEL=info
LOG_PRETTY=true

# CORS
CORS_ORIGIN=*
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

The server will start on `http://localhost:3200`.

## API Endpoints

### POST /agent

Main A2UI agent endpoint. Accepts user messages and returns SSE stream with A2UI JSONL messages.

**Request**:
```json
{
  "threadId": "uuid",
  "runId": "run_timestamp_random",
  "message": "Hello, show me a form",
  "surfaceId": "main",
  "metadata": {
    "a2uiClientCapabilities": {
      "supportedCatalogIds": [
        "https://github.com/google/A2UI/blob/main/specification/v0_8/json/standard_catalog_definition.json"
      ]
    }
  }
}
```

**Response**: `text/event-stream` (JSONL format)

```
retry: 3000

data: {"surfaceUpdate":{"surfaceId":"main","components":[{"id":"root","component":{"Column":{"children":{"explicitList":["header"]}}}}]}}

data: {"surfaceUpdate":{"surfaceId":"main","components":[{"id":"header","component":{"Text":{"text":{"literalString":"Hello"}}}}]}}

data: {"dataModelUpdate":{"surfaceId":"main","contents":[]}}

data: {"beginRendering":{"surfaceId":"main","root":"root"}}
```

### POST /action

Handle user interactions from A2UI widgets.

**Request**:
```json
{
  "userAction": {
    "name": "submit_form",
    "surfaceId": "main",
    "sourceComponentId": "submit-btn",
    "timestamp": "2025-01-27T10:00:00Z",
    "context": {
      "name": "John Doe",
      "email": "john@example.com"
    }
  }
}
```

**Response**: 
- If UI update needed: SSE stream with new A2UI messages
- Otherwise: `{"status":"ok","message":"Action received"}`

### GET /health

Health check endpoint.

**Response**:
```json
{
  "status": "ok",
  "timestamp": "2025-01-27T10:00:00.000Z",
  "uptime": 123.45,
  "sessions": 5,
  "version": "1.0.0"
}
```

## Agent Types

### Scenario Agent (Default)

Pre-scripted A2UI responses for deterministic testing.

**Available Scenarios**:
- `simple-ui` - Basic UI with Text and Button
- `form-ui` - Complex form with multiple input types
- `interactive-ui` - UI with data binding and dynamic updates

**Usage**:
```bash
# Default scenario mode
DEFAULT_AGENT=scenario npm run dev
```

### LLM Agent

Generate A2UI messages using LLM (Gemini or DeepSeek).

**Setup Gemini**:
1. Get API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Configure:
```env
DEFAULT_AGENT=llm
LLM_PROVIDER=gemini
GEMINI_API_KEY=your-gemini-api-key
```

**Setup DeepSeek**:
1. Get API key from [DeepSeek Platform](https://platform.deepseek.com/)
2. Configure:
```env
DEFAULT_AGENT=llm
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat
```

## A2UI Protocol Overview

### Message Format

All messages use JSON Lines (JSONL) format - one JSON object per line:

```json
{"surfaceUpdate":{"surfaceId":"main","components":[...]}}
{"dataModelUpdate":{"surfaceId":"main","contents":[...]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
```

### Message Types

1. **surfaceUpdate** - Define or update UI components
2. **dataModelUpdate** - Update data model for data binding
3. **beginRendering** - Signal client to render (must come after components are defined)
4. **deleteSurface** - Remove a surface from UI

### Component Model

A2UI uses a **flat adjacency list model** where components reference children by ID:

```json
{
  "surfaceUpdate": {
    "surfaceId": "main",
    "components": [
      {
        "id": "root",
        "component": {
          "Column": {
            "children": {
              "explicitList": ["text1", "button1"]
            }
          }
        }
      },
      {
        "id": "text1",
        "component": {
          "Text": {
            "text": {
              "literalString": "Hello"
            }
          }
        }
      }
    ]
  }
}
```

### Data Binding

Components can bind to data model using `path`:

```json
{
  "component": {
    "Text": {
      "text": {
        "path": "/user/name"
      }
    }
  }
}
```

Data model is updated separately:

```json
{
  "dataModelUpdate": {
    "surfaceId": "main",
    "path": "user",
    "contents": [
      {
        "key": "name",
        "valueString": "John Doe"
      }
    ]
  }
}
```

## Testing

### cURL Examples

**Send agent request**:
```bash
curl -X POST http://localhost:3200/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1",
    "message": "hello"
  }'
```

**Send user action**:
```bash
curl -X POST http://localhost:3200/action \
  -H "Content-Type: application/json" \
  -d '{
    "userAction": {
      "name": "increment",
      "surfaceId": "main",
      "sourceComponentId": "increment-btn",
      "timestamp": "2025-01-27T10:00:00Z",
      "context": {
        "currentValue": 5
      }
    }
  }'
```

### Unit Tests

```bash
npm test
```

## Development

### Project Structure

```
a2ui-test-server/
├── src/
│   ├── server.ts              # Fastify server setup
│   ├── routes/
│   │   ├── agent.ts           # A2UI agent endpoint
│   │   ├── action.ts          # User action handler
│   │   └── health.ts          # Health check
│   ├── agents/
│   │   ├── base.ts            # Base agent class
│   │   ├── scenario.ts        # Scenario-based agent
│   │   └── llm.ts             # LLM-powered agent
│   ├── scenarios/
│   │   ├── index.ts           # Scenario loader
│   │   ├── simple-ui.json     # Simple UI scenario
│   │   ├── form-ui.json       # Form UI scenario
│   │   └── interactive-ui.json # Interactive UI scenario
│   ├── streaming/
│   │   ├── jsonl-encoder.ts  # JSONL encoder for SSE
│   │   └── session.ts         # Session management
│   ├── types/
│   │   ├── a2ui.ts            # A2UI message types
│   │   └── scenario.ts        # Scenario types
│   └── utils/
│       ├── config.ts          # Configuration loader
│       ├── logger.ts          # Logger setup
│       └── validation.ts     # Input validation
├── tests/
├── .env.example
├── package.json
└── README.md
```

## References

- [A2UI Protocol Specification](https://a2ui.org/specification/v0.8-a2ui/)
- [A2UI Message Reference](https://a2ui.org/reference/messages/)
- [A2UI GitHub Repository](https://github.com/google/A2UI)

## License

MIT License - see [LICENSE](../../../LICENSE) for details

---

**Made with ❤️ by the FinClip team**
