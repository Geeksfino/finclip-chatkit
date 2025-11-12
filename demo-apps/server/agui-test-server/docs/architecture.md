# Architecture

## Overview

The AG-UI Test Server is designed as a modular, extensible system for testing AG-UI protocol implementations. It follows a layered architecture with clear separation of concerns.

## System Architecture

```text
┌─────────────────────────────────────────────────────────┐
│ HTTP Layer (Fastify)                                    │
│ ├─ POST /agent      - Main AG-UI endpoint              │
│ ├─ GET /health      - Health check                      │
│ ├─ GET /scenarios   - List scenarios                    │
│ └─ POST /scenarios/:id - Run scenario                   │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Request Handler Layer                                   │
│ ├─ Input validation (RunAgentInput schema)             │
│ ├─ Session management (threadId tracking)              │
│ └─ Agent factory (scenario/echo/llm selection)         │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Agent Layer                                             │
│ ├─ BaseAgent (abstract interface)                      │
│ ├─ ScenarioAgent (pre-scripted responses)              │
│ ├─ EchoAgent (test/debug)                              │
│ └─ LLMAgent (LiteLLM/DeepSeek integration)             │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│ Streaming Layer                                         │
│ ├─ SSEEncoder (@ag-ui/encoder wrapper)                 │
│ ├─ Event serialization (JSON)                          │
│ └─ Session state management                            │
└─────────────────────────────────────────────────────────┘
```

## Core Components

### 1. HTTP Layer (Fastify)

**Responsibilities**:

- Accept HTTP POST requests
- Validate headers and content-type
- Stream SSE responses
- Handle CORS
- Provide health checks

**Key Files**:

- `src/server.ts` - Main server setup
- `src/routes/*.ts` - Route handlers

### 2. Request Handler Layer

**Responsibilities**:

- Validate `RunAgentInput` schema
- Manage session state
- Select appropriate agent
- Handle errors

**Key Files**:

- `src/routes/agent.ts` - Main handler
- `src/routes/agent-factory.ts` - Agent selection
- `src/utils/validation.ts` - Input validation

### 3. Agent Layer

**Responsibilities**:

- Implement AG-UI agent logic
- Generate event streams
- Handle tool calls
- Manage conversation state

**Key Files**:

- `src/agents/base.ts` - Base interface
- `src/agents/scenario.ts` - Scenario playback
- `src/agents/echo.ts` - Echo agent
- `src/agents/llm.ts` - LLM integration

### 4. Streaming Layer

**Responsibilities**:

- Encode events to SSE format
- Manage SSE connections
- Track active sessions
- Handle cleanup

**Key Files**:

- `src/streaming/encoder.ts` - SSE encoding
- `src/streaming/session.ts` - Session management

## Data Flow

### Inbound Request Flow

```text
1. Client sends POST /agent with RunAgentInput
   ↓
2. Fastify receives request
   ↓
3. Validate input schema
   ↓
4. Create/update session
   ↓
5. Select agent via factory
   ↓
6. Initialize SSE stream
   ↓
7. Run agent.run(input)
   ↓
8. Stream events back to client
```

### Event Generation Flow

```text
Agent.run(input)
   ↓
Generate BaseEvent objects
   ↓
Yield events via AsyncGenerator
   ↓
SSEEncoder.encode(event)
   ↓
Write to HTTP response stream
   ↓
Client receives SSE events
```

## Agent Abstraction

All agents implement the `AGUIAgent` interface:

```typescript
interface AGUIAgent {
  run(input: RunAgentInput): AsyncGenerator<BaseEvent>;
}
```

This allows:

- Easy addition of new agent types
- Consistent event streaming
- Testability via mocking
- Runtime agent switching

## Session Management

Sessions are tracked by `threadId`:

```typescript
interface SessionState {
  threadId: string;
  messages: Message[];
  createdAt: Date;
  lastActivity: Date;
}
```

**Lifecycle**:

1. Created on first request with threadId
2. Updated on each subsequent request
3. Cleaned up after 1 hour of inactivity

## Configuration

Configuration is loaded from environment variables:

```typescript
interface ServerConfig {
  port: number;
  host: string;
  defaultAgent: string;
  llmProvider: string;
  // ... more config
}
```

**Loading Order**:

1. `.env` file (via dotenv)
2. Environment variables
3. Default values

## Error Handling

**Validation Errors**:

- Return 400 Bad Request
- Include error details in response

**Agent Errors**:

- Emit `RUN_ERROR` event
- Log error details
- Close SSE stream gracefully

**Server Errors**:

- Return 500 Internal Server Error
- Log full error context
- Maintain service availability

## Extensibility Points

### Adding New Agent Types

1. Create new class extending `BaseAgent`
2. Implement `run()` method
3. Register in `agent-factory.ts`
4. Add configuration options

### Adding New Scenarios

1. Create JSON file in `src/scenarios/`
2. Register in `src/scenarios/index.ts`
3. Test via `/scenarios/:id` endpoint

### Adding New Routes

1. Create route file in `src/routes/`
2. Register in `src/server.ts`
3. Add tests

## Performance Considerations

**Streaming**:

- Events streamed immediately (no buffering)
- Minimal memory footprint
- Supports concurrent connections

**Session Cleanup**:

- Automatic cleanup every 10 minutes
- Configurable max age
- No memory leaks

**LLM Integration**:

- Streaming responses from LLM
- No blocking operations
- Proper error handling

## Security

**Input Validation**:

- Strict schema validation
- Type checking
- Size limits

**CORS**:

- Configurable origins
- Credentials support

**Rate Limiting**:

- Can be added via Fastify plugin
- Per-IP or per-threadId

## Testing Strategy

**Unit Tests**:

- Agent logic
- Event encoding
- Validation functions

**Integration Tests**:

- Full request/response flow
- SSE streaming
- Session management

**E2E Tests**:

- NeuronKit integration
- Real LLM calls
- Error scenarios

## Deployment

**Development**:

- Hot reload via tsx
- Pretty logging
- Debug mode

**Production**:

- Compiled TypeScript
- JSON logging
- Process management (PM2/systemd)
- Docker containerization

## Monitoring

**Metrics**:

- Request count
- Response time
- Active sessions
- Error rates

**Logging**:

- Structured JSON logs
- Request/response tracking
- Error details
- Performance metrics

## Future Enhancements

1. **Binary Protocol Support** - Add `@ag-ui/proto` for binary transport
2. **WebSocket Support** - Alternative to SSE
3. **State Persistence** - Redis/database backing
4. **Advanced Scenarios** - Multi-turn, branching flows
5. **Metrics Dashboard** - Real-time monitoring UI
6. **Authentication** - Bearer token support
7. **Rate Limiting** - Built-in rate limiting
8. **Caching** - Response caching for scenarios
