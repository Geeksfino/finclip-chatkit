# Demo Backend Servers

Backend servers for testing ChatKit demo applications. These servers implement the protocols required by ChatKit's iOS demos and provide various agent types for testing different scenarios.

## 📦 Available Servers

### agui-test-server
**AG-UI protocol test server** with multiple agent types including:
- 🎭 Scenario-based (pre-scripted responses)
- 🔄 Echo agent (simple testing)
- 🤖 LiteLLM integration (real LLM via proxy)
- 🧠 DeepSeek integration (direct API)

**Best for**: Testing iOS demos with predictable responses or real AI.

[→ agui-test-server Documentation](agui-test-server/README.md)

### mcpui-test-server  
**MCP-UI protocol test server** for testing interactive web components and widgets.

**Best for**: Testing advanced UI components like forms, buttons, and embedded widgets.

[→ mcpui-test-server Documentation](mcpui-test-server/README.md)

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
# Navigate to server directory
cd demo-apps/server/mcpui-test-server

# Install dependencies
npm install
# or
pnpm install

# Start server
npm run dev
```

---

## 🔧 Configuration

### agui-test-server Configuration

Edit `agui-test-server/.env`:

```env
# Server settings
PORT=3000                    # Port to listen on
HOST=0.0.0.0                 # Host to bind to

# Agent type (choose one)
DEFAULT_AGENT=scenario       # Pre-scripted responses (recommended for testing)
# DEFAULT_AGENT=echo         # Simple echo agent
# DEFAULT_AGENT=litellm      # LiteLLM proxy integration
# DEFAULT_AGENT=deepseek     # Direct DeepSeek API

# LiteLLM settings (if using DEFAULT_AGENT=litellm)
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_API_KEY=your-key
LITELLM_MODEL=deepseek-chat

# DeepSeek settings (if using DEFAULT_AGENT=deepseek)
DEEPSEEK_API_KEY=your-deepseek-api-key
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com
```

### mcpui-test-server Configuration

Edit `mcpui-test-server/.env`:

```env
PORT=3001                    # Different port to avoid conflicts
HOST=0.0.0.0
```

---

## 📱 Using with iOS Demos

### Simple Demo (Swift)

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

### SimpleObjC Demo (Objective-C)

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

### Scenario Agent (Default - Recommended)

**Use when**: You want predictable, deterministic responses for testing.

Pre-scripted responses based on conversation patterns. Perfect for:
- Unit testing
- Demo recordings
- Reproducible behavior

**Available scenarios**:
- `simple-chat` - Basic conversation
- `tool-call` - Feature invocation demo
- `error-handling` - Error scenarios

### Echo Agent

**Use when**: You just want to test connectivity and message flow.

Simply echoes back whatever the user sends. Good for:
- Testing networking
- Debugging message format
- Sanity checks

Enable with:
```env
DEFAULT_AGENT=echo
```

### LiteLLM Agent

**Use when**: You want real AI responses from any LLM provider.

Connects to a LiteLLM proxy that can route to OpenAI, Anthropic, DeepSeek, etc.

**Setup**:
1. Install LiteLLM:
   ```bash
   pip install litellm
   ```

2. Start LiteLLM proxy:
   ```bash
   litellm --model deepseek/deepseek-chat --api_key $DEEPSEEK_API_KEY
   ```

3. Configure server:
   ```env
   DEFAULT_AGENT=litellm
   LITELLM_ENDPOINT=http://localhost:4000/v1
   ```

### DeepSeek Agent

**Use when**: You want direct DeepSeek API integration without LiteLLM.

Fastest path to real AI responses with DeepSeek.

**Setup**:
1. Get API key from [DeepSeek](https://platform.deepseek.com/)

2. Configure server:
   ```env
   DEFAULT_AGENT=deepseek
   DEEPSEEK_API_KEY=your-key-here
   ```

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

### iOS app can't connect - "Network error"

1. **Check server is running**:
   ```bash
   curl http://localhost:3000/health
   ```

2. **If using iOS Simulator**: `localhost` and `127.0.0.1` work fine

3. **If using physical device**: 
   - Use your Mac's local IP instead (e.g., `http://192.168.1.100:3000`)
   - Find IP: `System Settings → Network → Wi-Fi → Details → IP address`
   - Ensure device and Mac are on same Wi-Fi network

### LiteLLM/DeepSeek not responding

1. **Check API key is set**:
   ```bash
   echo $DEEPSEEK_API_KEY
   ```

2. **Test API directly**:
   ```bash
   curl https://api.deepseek.com/v1/chat/completions \
     -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
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
- [mcpui-test-server README](mcpui-test-server/README.md) - Full MCP-UI server documentation
- [ChatKit Developer Guide](../../docs/guides/developer-guide.md) - iOS SDK integration guide
- [AG-UI Protocol Spec](agui-test-server/docs/agui-compliance.md) - Protocol specification

---

## 🤝 Support

Having issues? Check:
1. This troubleshooting section above
2. Server-specific READMEs for detailed docs
3. [ChatKit Troubleshooting Guide](../../docs/troubleshooting.md)
4. [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**Happy Testing! 🚀**
