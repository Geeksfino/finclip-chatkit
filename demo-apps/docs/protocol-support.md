# Protocol & Convention Support

ChatKit supports multiple conventions so agent responses can include **interactive UI**, not just text.

## AG-UI (Agent UI) Protocol

AG-UI support enables SSE + HTTP event-driven agent experiences (streaming text, tool calls, multi-session).

**Key Features:**
- ✅ **Full SSE Event Support** - All AG-UI event types (`RUN_*`, `TEXT_MESSAGE_*`, `TOOL_CALL_*`, etc.)
- ✅ **Typed Tool Arguments** - Preserves JSON types (numbers, booleans, objects, arrays) instead of converting to strings
- ✅ **Multi-Session SSE** - Multiple concurrent conversation sessions with separate SSE connections
- ✅ **Text Streaming** - Real-time incremental text streaming with sequence tracking
- ✅ **Tool/Function Calls** - Agent requests tool execution with proper consent flow via Sandbox PDP
- ✅ **Thread Management** - Track conversation threads with `runId` and metadata
- ✅ **Bidirectional Communication** - HTTP POST for outbound messages, SSE for inbound streaming

**Usage:**
```swift
import FinClipChatKit

let config = NeuronKitConfig.default(serverURL: URL(string: "https://your-agui-server.com/agent")!)
    .withUserId("user-123")

let coordinator = ChatKitCoordinator(config: config)

// Configure AG-UI adapter
let aguiAdapter = AGUI_Adapter(
    baseEventURL: URL(string: "https://your-agui-server.com/agent")!,
    connectionMode: .postStream  // POST with SSE responses
)
coordinator.runtime.setNetworkAdapter(aguiAdapter)

// Start conversation - AG-UI protocol is automatically used
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)
```

**Connection Modes:**
- **POST Stream** (Recommended): Single endpoint for both sending messages and receiving SSE responses
- **Event Stream**: Separate endpoints for SSE connection and message sending

See: AG-UI usage in docs and examples (start here: [Architecture Overview](architecture/overview.md)).

## OpenAI Apps SDK Bridge

Compatibility bridge for OpenAI-style widgets (`window.openai`) rendered inside ChatKit.

**Key Features:**
- ✅ **`window.openai` API** - Full JavaScript API compatibility
- ✅ **Promise-Based Architecture** - Async/await support for tool calls and state operations
- ✅ **State Management** - Built-in `setState()` and `getState()` for widget state persistence
- ✅ **Event System** - Support for `on()` and `off()` event handlers
- ✅ **Native Integration** - Uses WKWebView and WKScriptMessageHandler for secure bridge communication

**Usage:**
Widgets from OpenAI Apps SDK-based MCP servers are automatically rendered in ChatKit's conversation UI. The bridge handles all JavaScript-to-native communication transparently.

**JavaScript API (in widgets):**
```javascript
// Promise-based tool calls
window.openai.callTool({
    name: "get_weather",
    parameters: { location: "San Francisco" }
}).then(result => {
    console.log("Weather:", result);
});

// State management
window.openai.setState({ count: 5 });
const state = window.openai.getState(); // { count: 5 }
```

## MCP-UI Support

Render MCP-UI widgets in a secure WKWebView environment (`window.mcpUI`) with sandboxed actions.

**Key Features:**
- ✅ **Native WKWebView Rendering** - Secure, sandboxed execution for web compatibility
- ✅ **Fire-and-Forget Actions** - Simple action pattern (`callTool`, `triggerIntent`, `submitPrompt`, `notify`, `openLink`)
- ✅ **Auto-Resize Support** - Dynamic content sizing via `reportSize()`
- ✅ **Render Data Injection** - Dynamic content injection for widget personalization
- ✅ **Security Sandboxing** - WKWebView with Content Security Policy (CSP) enforcement
- ✅ **Multiple Content Types** - Support for HTML (`text/html`), external URLs (`text/uri-list`), and remote DOM scripts

**Usage:**
MCP-UI widgets are automatically detected and rendered in ChatKit's conversation UI. Actions from widgets are handled through the conversation's delegate methods.

**JavaScript API (in widgets):**
```javascript
// Call a tool/function on the backend
window.mcpUI.callTool("search", { query: "example" });

// Trigger an intent
window.mcpUI.triggerIntent("book_flight", { destination: "NYC" });

// Submit a new prompt
window.mcpUI.submitPrompt("Tell me more about...");

// Show a notification
window.mcpUI.notify("Operation completed", "success");

// Open a link
window.mcpUI.openLink("https://example.com");

// Report widget size for auto-resize
window.mcpUI.reportSize(450);
```

> All conventions can be combined: AG-UI handles agent communication; widgets are rendered via the OpenAI Bridge or MCP-UI depending on type.

