# Demo Backend Servers

Backend servers for testing ChatKit demo applications. These servers implement the protocols required by ChatKit's mobile app demos and provide various agent types for testing different scenarios.

## 📦 Available Servers

### agui-test-server
**AG-UI protocol test server** with multiple agent types including:
- 🎭 Scenario-based (pre-scripted responses)
- 🔄 Echo agent (simple testing)
- 🤖 LiteLLM integration (real LLM via proxy)
- 🧠 DeepSeek integration (direct API)

**Best for**: Testing mobile app demos with predictable responses or real AI.

[→ agui-test-server Documentation](agui-test-server/README.md)

### mcpui-test-server  
**MCP-UI / MCP Apps protocol test server** for testing interactive web components and widgets.

> **📌 Protocol Update**: MCP-UI has been standardized as MCP Apps. This server supports both MCP Apps standard and legacy MCP-UI protocol. Learn more at [mcpui.dev](https://mcpui.dev/).

**Best for**: Testing advanced UI components like forms, buttons, and embedded widgets.

[→ mcpui-test-server Documentation](mcpui-test-server/README.md)

### a2ui-test-server
**A2UI protocol test server** for testing declarative UI generation from AI agents.

**Best for**: Testing A2UI protocol integration, scenario-based UI generation, and LLM-powered UI creation.

[→ a2ui-test-server Documentation](a2ui-test-server/README.md)

---

## 🚀 Quick Start

### Prerequisites

- **Node.js 20+** ([Download](https://nodejs.org/))
- **npm** (included with Node.js) or **pnpm** (recommended)

Install pnpm (optional but faster):
```bash
npm install -g pnpm
```

### Running agui-test-server (Recommended for Getting Started)

This is the server you'll use most often with the iOS demos:

```bash
# Navigate to server directory
cd demo-apps/server/agui-test-server

# Install dependencies
npm install
# or
pnpm install

# Configure environment (optional)
cp .env.example .env
# Edit .env if needed (defaults work fine)

# Start server in development mode
npm run dev
```

The server will start on **http://localhost:3000**

You should see:
```
✓ Server listening at http://0.0.0.0:3000
✓ Default agent type: scenario
```

### Running mcpui-test-server

```bash
cd demo-apps/server/mcpui-test-server
npm install
npm run dev
```

Server runs on **http://localhost:3100**.

### Running a2ui-test-server

```bash
cd demo-apps/server/a2ui-test-server
npm install
npm run dev
```

Server runs on **http://localhost:3200**. Required when using agui-test-server with `EXTENSION_MODE=a2ui`.

---

## 🔧 Configuration

### agui-test-server Configuration

Edit `agui-test-server/.env` (see `.env.example` for full options):

```env
# Server
PORT=3000
HOST=0.0.0.0

# Agent mode: emulated | llm
AGENT_MODE=emulated          # Pre-scripted (default) or real LLM

# When AGENT_MODE=emulated: scenario ID (echo | simple-chat | tool-call | error-handling)
DEFAULT_SCENARIO=tool-call

# When AGENT_MODE=llm: LLM provider (deepseek | openai | siliconflow | litellm)
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
LLM_API_KEY=your-api-key

# Extension mode: none | mcpui | a2ui (enables MCPUI tools or A2UI proxy)
EXTENSION_MODE=none
MCPUI_SERVER_URL=http://localhost:3100/mcp   # When EXTENSION_MODE=mcpui
A2UI_SERVER_URL=http://localhost:3200        # When EXTENSION_MODE=a2ui
```

### mcpui-test-server Configuration

Edit `mcpui-test-server/.env`:

```env
PORT=3100                    # MCP server (agui connects here when EXTENSION_MODE=mcpui)
HOST=0.0.0.0
```

### a2ui-test-server Configuration

Edit `a2ui-test-server/.env`:

```env
PORT=3200
HOST=0.0.0.0
```

---

## 📱 Using with Mobile App Demos

### iOS Simple Demo (Swift)

1. **Start the server**:
   ```bash
   cd demo-apps/server/agui-test-server
   npm run dev
   ```

2. **Run the iOS app**:
   ```bash
   cd demo-apps/iOS/Simple
   make run
   ```

3. **In the app**:
   - Default server URL is already set to `http://127.0.0.1:3000/agent`
   - Tap "Connect" → Tap "+" to create a conversation
   - Start chatting!

### iOS SimpleObjC Demo (Objective-C)

Same steps as above, but run:
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

---

## 🧪 Testing the Server

### Quick Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-11-12T09:43:41.000Z",
  "uptime": 123.45,
  "sessions": 0
}
```

### Test a Simple Chat

```bash
curl -X POST http://localhost:3000/agent \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1731405821_abc",
    "messages": [
      {
        "id": "msg-1",
        "role": "user",
        "content": "Hello"
      }
    ],
    "tools": [],
    "context": [],
    "state": null
  }'
```

You'll see a stream of Server-Sent Events (SSE):
```
event: message
data: {"type":"RUN_STARTED","threadId":"test-123","runId":"run_1731405821_abc"}

event: message
data: {"type":"TEXT_MESSAGE_CHUNK","messageId":"msg-xxx","delta":"Hello"}

event: message
data: {"type":"RUN_FINISHED","threadId":"test-123","runId":"run_1731405821_abc"}
```

### List Available Scenarios

```bash
curl http://localhost:3000/scenarios
```

---

## 🔄 Agent Types Explained

### Scenario Agent (Emulated - Default)

**Use when**: You want predictable responses for testing.

Set `AGENT_MODE=emulated` and `DEFAULT_SCENARIO=<id>`:
- `simple-chat` - Basic conversation
- `tool-call` - Feature invocation demo
- `error-handling` - Error scenarios

### Echo Agent

Set `AGENT_MODE=emulated` and `DEFAULT_SCENARIO=echo` to echo user input.

### LLM Agent

**Use when**: You want real AI responses.

1. Set `AGENT_MODE=llm` (or run `npm run dev -- --use-llm`)
2. Configure `LLM_PROVIDER`, `LLM_MODEL`, `LLM_API_KEY` in `.env`
3. Supported providers: `deepseek`, `openai`, `siliconflow`, `litellm`

See [agui-test-server README](agui-test-server/README.md) for full configuration.

---

## 🛠️ Development

### Hot Reload

Both servers support hot reload in development mode:

```bash
npm run dev
```

Code changes automatically restart the server.

### Building for Production

```bash
# Build
npm run build

# Run production build
npm start
```

### Running Tests

```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage
```

---

## 🐛 Troubleshooting

### Server won't start - "Port already in use"

Another process is using port 3000:

```bash
# Find what's using the port
lsof -i :3000

# Kill the process (replace PID with actual process ID)
kill -9 PID
```

Or change the port in `.env`:
```env
PORT=3001
```

### Mobile app can't connect - "Network error"

1. **Check server is running**:
   ```bash
   curl http://localhost:3000/health
   ```

2. **If using emulator/simulator**:
   - iOS Simulator: `localhost` and `127.0.0.1` work fine
   - Android Emulator: Use `10.0.2.2` instead of `localhost`

3. **If using physical device**: 
   - Use your development machine's local IP instead (e.g., `http://192.168.1.100:3000`)
   - Find IP: `System Settings → Network → Wi-Fi → Details → IP address` (macOS) or network settings (other systems)
   - Ensure device and development machine are on same Wi-Fi network

### LLM not responding

1. **Check API key is set** (from agui `.env`):
   ```bash
   echo $LLM_API_KEY
   ```

2. **Test API directly** (DeepSeek example):
   ```bash
   curl https://api.deepseek.com/v1/chat/completions \
     -H "Authorization: Bearer $LLM_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"hi"}]}'
   ```

3. **Check server logs** for specific error messages

### Dependencies won't install

1. **Clear cache and reinstall**:
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **Try pnpm** (often more reliable):
   ```bash
   npm install -g pnpm
   pnpm install
   ```

---

## 📚 Further Reading

- [agui-test-server README](agui-test-server/README.md) - Full AG-UI server documentation
- [mcpui-test-server README](mcpui-test-server/README.md) - MCP-UI server documentation
- [a2ui-test-server README](a2ui-test-server/README.md) - A2UI server documentation
- [ChatKit Developer Guide](../../docs/guides/developer-guide.md) - Mobile SDK integration guide
- [agui-test-server docs](agui-test-server/docs/) - architecture, agui-compliance, resilience

---

## 🤝 Support

Having issues? Check:
1. This troubleshooting section above
2. Server-specific READMEs for detailed docs
3. [ChatKit Troubleshooting Guide](../../docs/troubleshooting.md)
4. [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**Happy Testing! 🚀**
