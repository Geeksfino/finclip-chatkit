# Running the Demo Applications

Quick guide to get ChatKit demos running with the backend server.

## TL;DR - Get Started in 5 Minutes

> **Note:** By default, the server uses **emulated responses** (pre-scripted scenarios). To use **real AI** (DeepSeek or other LLM providers), see [Using Real AI](#using-real-ai-deepseek-or-other-llm-providers) below.

### Terminal 1: Start Backend Server

```bash
cd demo-apps/server/agui-test-server
npm install  # First time only
npm run dev  # Uses emulated responses by default
```

Wait for: `✓ Server listening at http://0.0.0.0:3000`

### Terminal 2: Run iOS Demo

**Swift Demo:**
```bash
cd demo-apps/iOS/Simple
make run
```

**Objective-C Demo:**
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

That's it! The app will launch on the iOS Simulator and connect to the server.

---

## Detailed Instructions

### Step 1: Install Prerequisites

#### For Backend Server
- **Node.js 20+**: [Download](https://nodejs.org/) or install via Homebrew:
  ```bash
  brew install node
  ```

#### For iOS Apps
- **Xcode 15.0+**: [Download from Mac App Store](https://apps.apple.com/us/app/xcode/id497799835)
- **XcodeGen**: 
  ```bash
  brew install xcodegen
  ```

### Step 2: Start the Backend Server

The backend server provides the AI agent that responds to chat messages.

**Two modes available:**
- **Emulated mode** (default): Uses pre-scripted scenarios, no API keys needed
- **LLM mode**: Uses real AI providers (DeepSeek, OpenAI, etc.) - requires configuration

#### Starting in Emulated Mode (Default)

```bash
# Navigate to server directory
cd demo-apps/server/agui-test-server

# Install dependencies (first time only)
npm install

# Start in emulated mode (pre-scripted responses)
npm run dev
```

#### Starting in LLM Mode (Real AI)

First configure your LLM provider (see [Using Real AI](#using-real-ai-deepseek-or-other-llm-providers)), then:

```bash
# Start with LLM provider enabled
npm run dev --use-llm
```

**Expected output:**
```
[11:43:41.000] INFO: Starting AG-UI test server...
[11:43:41.123] INFO: Agent mode: emulated  # or "llm" if using --use-llm
[11:43:41.456] INFO: Server listening at http://0.0.0.0:3000
```

**Server is ready when you see**: `✓ Server listening`

**Don't close this terminal** - keep the server running while using the iOS apps.

### Step 3: Run an iOS Demo

Open a **new terminal window** and choose either demo:

#### Option A: Simple (Swift) - Recommended

```bash
cd demo-apps/iOS/Simple

# Generate Xcode project from project.yml
make generate

# Build and run on simulator
make run
```

**Alternative** - Open in Xcode:
```bash
make open
# Then press Cmd+R to build and run
```

#### Option B: SimpleObjC (Objective-C)

```bash
cd demo-apps/iOS/SimpleObjC

# Generate Xcode project from project.yml
make generate

# Build and run on simulator
make run
```

### Step 4: Use the App

**Simple (Swift):**
1. Tap hamburger menu (≡) to open drawer
2. Tap "+" to create new conversation
3. Type "Hello" and tap send
4. Agent responds automatically

**SimpleObjC (Objective-C):**
1. On connection screen, tap "Connect"
2. Tap "+" in conversation list
3. Type "Hello" and tap send
4. Agent responds automatically

---

## Troubleshooting

### Server Issues

#### "Port already in use"
```bash
# Find what's using port 3000
lsof -i :3000

# Kill the process (replace PID)
kill -9 PID
```

Or use a different port in `demo-apps/server/agui-test-server/.env`:
```env
PORT=3001
```

#### "Command not found: npm"
Install Node.js:
```bash
brew install node
```

#### Dependencies won't install
```bash
cd demo-apps/server/agui-test-server
rm -rf node_modules package-lock.json
npm install
```

### iOS App Issues

#### "Command not found: xcodegen"
```bash
brew install xcodegen
```

#### "Build failed" or "Scheme not found"
```bash
cd demo-apps/iOS/Simple  # or SimpleObjC
make clean
make generate
make run
```

#### "Cannot connect to server"

1. **Verify server is running:**
   ```bash
   curl http://localhost:3000/health
   ```
   Should return: `{"status":"ok",...}`

2. **Check app server URL** (should be `http://127.0.0.1:3000/agent`)
   - **Simple**: See `App/App/AppConfig.swift`
   - **SimpleObjC**: See `App/Coordinators/ChatCoordinator.m`

3. **If using physical device**, change URL to your Mac's IP:
   ```swift
   // Find your Mac's IP: System Settings → Network → Wi-Fi → Details
   http://192.168.1.100:3000/agent  // Replace with your IP
   ```

#### "Simulator not found: iPhone 17"
The simulator device doesn't exist. List available devices:
```bash
xcrun simctl list devices available
```

Then update the Makefile or run with a different device:
```bash
make run SIMULATOR_DEVICE="iPhone 16"
```

---

## Advanced Usage

### Using Real AI (DeepSeek or Other LLM Providers)

To use real AI instead of emulated responses, you need to configure an LLM provider.

**We recommend using DeepSeek** as it provides high-quality responses at low cost.

#### Step 1: Get an API Key

Get your API key from [DeepSeek Platform](https://platform.deepseek.com/) (or your preferred OpenAI-compatible provider).

#### Step 2: Configure the Environment

Copy the example configuration file:

```bash
cd demo-apps/server/agui-test-server
cp .env.example .env
```

Then edit `.env` with your preferred configuration:

**Option A: Direct DeepSeek (Recommended)**
```env
# Uncomment these lines:
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sk-your-deepseek-key-here
DEEPSEEK_MODEL=deepseek-chat
```

**Option B: Via LiteLLM (supports multiple providers)**
```env
LLM_PROVIDER=litellm
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_MODEL=deepseek-chat
LITELLM_API_KEY=your-api-key-here
```

> **Note:** LiteLLM acts as a proxy that supports multiple LLM providers with a unified interface. You'll need to set up LiteLLM separately if using this option.

#### Step 3: Start Server with LLM Mode

**Important:** You must use the `--use-llm` flag to enable LLM mode:

```bash
npm run dev --use-llm
```

**Expected output:**
```
[11:43:41.000] INFO: Starting AG-UI test server...
[11:43:41.123] INFO: Agent mode: llm          # ← Confirms LLM mode is active
[11:43:41.234] INFO: LLM provider: deepseek   # ← Shows your provider
[11:43:41.456] INFO: Server listening at http://0.0.0.0:3000
```

Now your iOS app will get real AI responses!

**Troubleshooting:**
- If you see `Agent mode: emulated` instead of `llm`, make sure you included the `--use-llm` flag
- If you get API errors, verify your API key is correct in `.env`
- Check that `.env` file is in `demo-apps/server/agui-test-server/` directory

### Running on Physical Device

1. **Get your Mac's IP address:**
   - Go to: System Settings → Network → Wi-Fi → Details
   - Note the IP address (e.g., `192.168.1.100`)

2. **Ensure Mac and iPhone are on same Wi-Fi network**

3. **Update iOS app server URL:**

   **Simple (Swift)** - Edit `demo-apps/iOS/Simple/App/App/AppConfig.swift`:
   ```swift
   static let defaultServerURL = URL(string: "http://192.168.1.100:3000/agent")!
   ```

   **SimpleObjC** - Edit `demo-apps/iOS/SimpleObjC/App/Coordinators/ChatCoordinator.m`:
   ```objc
   NSURL *serverURL = [NSURL URLWithString:@"http://192.168.1.100:3000/agent"];
   ```

4. **Rebuild and run:**
   ```bash
   make clean
   make generate
   make run
   ```

### Viewing Server Logs

The server outputs detailed logs in development mode:

```bash
cd demo-apps/server/agui-test-server
npm run dev
```

**Log levels:**
- `INFO` - Normal operations
- `WARN` - Warnings (recoverable issues)
- `ERROR` - Errors (requests failed)

**Useful logs:**
- Incoming requests: `POST /agent`
- Agent responses: Message chunks and tool calls
- Connection issues: Client disconnects

---

## Next Steps

- **Customize the demos**: See demo README files for architecture details
- **Explore server options**: [Server Documentation](../demo-apps/server/README.md)
- **Build your own app**: [ChatKit Developer Guide](guides/developer-guide.md)
- **Understand protocols**: [AG-UI Spec](../demo-apps/server/agui-test-server/docs/agui-compliance.md)

---

## Quick Reference

### Common Commands

```bash
# Backend server
cd demo-apps/server/agui-test-server
npm install           # Install (first time)
npm run dev           # Start server
npm test              # Run tests
npm run build         # Build for production

# iOS Simple demo
cd demo-apps/iOS/Simple
make generate         # Generate Xcode project
make run              # Build and run
make clean            # Clean build artifacts
make open             # Open in Xcode

# iOS SimpleObjC demo
cd demo-apps/iOS/SimpleObjC
make generate         # Generate Xcode project
make run              # Build and run
make clean            # Clean build artifacts
```

### Default Configuration

| Component | Default Value |
|-----------|---------------|
| Server URL | `http://127.0.0.1:3000` |
| Server Port | `3000` |
| Agent Type | `scenario` (pre-scripted) |
| Agent ID | `E1E72B3D-845D-4F5D-B6CA-5550F2643E6B` |
| User ID | `demo-user` |
| iOS Simulator | iPhone 17 |

---

**Need Help?** See [Troubleshooting Guide](troubleshooting.md) or [open an issue](https://github.com/Geeksfino/finclip-chatkit/issues).
