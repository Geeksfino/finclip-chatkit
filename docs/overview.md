# FinClip ChatKit

[English](README.md) | [简体中文](README.zh.md)

**The conversational AI SDK for iOS apps.**

FinClip ChatKit is an embeddable SDK that lets you build intelligent, context-aware conversational experiences directly inside your iOS apps. It provides a drop-in chat interface, secure sandbox for agent actions, and native bridges for agent protocols such as AG-UI, OpenAI Apps SDK, and MCP-UI — all in one package.

Built for developers who want to add AI chat and agent-assisted actions quickly, ChatKit combines native UI performance with context awareness and security. It brings together real-time text streaming, multimedia rendering, and policy-based sandbox execution — so your app can talk, act, and reason safely.

Whether you’re building a personal assistant, support bot, or workflow automation tool, ChatKit helps you ship a production-ready conversational experience in hours instead of weeks.

## Why ChatKit?

Modern AI assistants need more than just text back-and-forth—they need to understand context, execute actions safely, and integrate seamlessly into your app's existing flows. ChatKit delivers:

**🧠 Context-Aware Intelligence**  
Automatically captures rich device signals—location, time, sensors, network status, calendar events—so your AI understands the user's situation without extra work from you. Context providers run efficiently in the background, enriching every conversation with relevant environmental data.

**🎨 Production-Ready UI Components**  
Ship chat experiences in hours, not weeks. Drop-in view controllers with rich message rendering (Markdown, multimedia, forms, buttons, cards), real-time streaming text, typing indicators, and support for press-to-talk speech input. Light/dark mode and full theming support included.

**🔒 Security-First Architecture**  
Every AI-initiated action runs through a capability-based sandbox with fine-grained policy controls. Require explicit user consent, enforce rate limits, set sensitivity levels, and maintain complete audit trails—all built-in. Your users stay in control, always.

**💾 Persistent Conversation Management**  
Multi-session support with automatic persistence. Track conversation history, resume sessions across app launches, manage multiple agents, and sync seamlessly with cloud storage—all handled by the framework's integrated storage layer.

**🔌 Flexible Integration**  
High-level APIs for rapid development (20-30 lines to a working chat UI) or low-level APIs when you need maximum control. Works with WebSocket/HTTP backends, supports custom network adapters, and embeds easily in navigation stacks, sheets, drawers, or tabs.

**📱 Native Performance**  
Pure iOS/Swift implementation with native WKWebView rendering for interactive components. No cross-platform compromises—built specifically for iOS with optimal memory usage and smooth 60fps scrolling even with hundreds of messages.

---

## Extensibility and Customization

ChatKit is designed for extensibility through a powerful **provider system**—a lightweight, plugin-like architecture that lets developers deeply customize how ChatKit behaves and interacts with users. By registering or replacing providers, you can adapt ChatKit to new use cases, integrate with enterprise infrastructure, or deliver richer, more contextual AI experiences.

### Context Providers
Developers can create custom context providers—“mini” interfaces that collect structured user input or contextual data (such as maps, calendars, or forms) and attach this information to user queries before sending them to the agent or LLM. These transient UIs can appear dynamically when the agent requests more context or when users trigger a context collection action. For example, you might present a date picker when scheduling, or a map interface for location selection, seamlessly gathering structured data to enhance agent reasoning.

### ASR Providers
Plug in any speech recognition engine using an ASR (Automatic Speech Recognition) provider. Whether you need Deepgram, OpenAI Whisper, Apple Dictation, or an enterprise-compliant speech engine, ChatKit allows you to swap or extend ASR providers to capture voice input, adapt to language requirements, or meet compliance needs—all without modifying the core SDK.

### Title Generators
Developers can inject custom auto-title generation logic to automatically name chat sessions or improve user experience. For instance, you could use a summary of the conversation, the user’s first message, or a custom LLM-based summarizer to generate descriptive and relevant session titles.

### Plugin-Like Flexibility
Each provider acts like a lightweight plugin: register, replace, or extend them easily to make your ChatKit-based app more powerful and contextually aware. Mix and match providers to support new modalities, enterprise integrations, or unique workflows—without forking or rewriting the SDK.

> ChatKit’s provider system makes it easy to go from a simple chat box to a deeply contextual, multimodal AI experience.

---

### What You Can Build

- **Customer support bots** with agent handoff and rich media attachments  
- **Personal AI assistants** that access device sensors and calendar to help users  
- **In-app shopping advisors** that understand user preferences and purchase history  
- **Health coaching apps** with context-aware recommendations based on time and location  
- **Enterprise automation** tools where AI proposes actions requiring user approval  
- **Educational tutors** with interactive forms, quizzes, and progress tracking

---

## How It Fits in the Agentic Ecosystem

ChatKit is part of the FinClip Agentic Middleware ecosystem, but it’s **fully open and server-agnostic** — you’re never locked to FinClip servers. Because it natively supports the **AG-UI protocol**, developers can host their own agent servers or build custom ones that speak AG-UI, enabling full control over backend logic, privacy, and data.

You can even **combine** AG-UI with **MCP-UI** or the **OpenAI Apps SDK** to provide generative UI capabilities. ChatKit will seamlessly interoperate with any compliant AG-UI or MCP-UI server, automatically rendering dynamic, agent-generated UI elements (buttons, forms, cards, etc.) within your iOS app.

ChatKit acts as the mobile-side runtime bridge for agent protocols like AG-UI (Agent UI) and MCP-UI (Model Context Protocol UI). Together, these protocols enable generative UI — where conversations dynamically generate interactive elements such as buttons, forms, and cards, rendered securely in iOS.

---

## 🚀 Quick Start

Get up and running in minutes! ChatKit provides high-level APIs that let you build a working chat app with just 20-30 lines of code.

**📖 For minimal skeleton code**: See the [Quick Start Guide](quick-start.md) for Swift and Objective-C templates (5 minutes).

**📚 For detailed walkthrough**: See the [Getting Started Guide](getting-started.md) for step-by-step instructions with explanations.

**Key steps:**
1. Add ChatKit dependency (see [Installation Guide](integration-guide.md))
2. Initialize `ChatKitCoordinator` at app launch
3. Create conversation when user requests it
4. Show ready-made chat UI with `ChatKitConversationViewController`

That's it! You now have a working AI chat app with persistent storage and full-featured UI.

### Sending Messages with Context

ChatKit provides a unified way to attach context to messages using `ChatKitContextItemFactory`. This factory creates `ConversationContextItem` instances from simple metadata dictionaries, making it easy to send programmatic context.

**📖 For complete examples**: See the [Context Providers Guide](guides/context-providers.md) for Swift and Objective-C examples of sending messages with context.

---

## 📚 Documentation

**📑 [Complete Documentation Index](README.md)** - Full navigation and learning paths

### Getting Started
- **[Quick Start Guide](quick-start.md)** - Minimal skeleton code (Swift & Objective-C) - **Start here!**
- **[Getting Started Guide](getting-started.md)** - Detailed walkthrough with explanations

### Core Guides

#### Swift
- **[Swift Developer Guide](guides/developer-guide.md)** - Comprehensive Swift guide from beginner to expert

#### Objective-C
- **[Objective-C Developer Guide](guides/objective-c-guide.md)** - Complete Objective-C guide with API reference

#### Shared Concepts
- **[API Levels Guide](api-levels.md)** - Understanding high-level vs low-level APIs
- **[Component Embedding Guide](component-embedding.md)** - Embed components in sheets, drawers, tabs (Swift & Objective-C)
- **[Context Providers Guide](guides/context-providers.md)** - Implementing custom context providers
- **[Configuration Guide](guides/configuration.md)** - Complete configuration reference

### Integration & Setup
- **[Integration Guide](integration-guide.md)** - Package managers (SPM, CocoaPods), installation, deployment
- **[Build Tooling Guide](build-tooling.md)** - Reproducible builds with Makefile and XcodeGen
- **[Remote Dependencies](remote-dependencies.md)** - Working with remote binary dependencies

### Customization
- **[Customize UI Guide](how-to/customize-ui.md)** - Styling and theming
- **[Prompt Starters Guide](guides/prompt-starters.md)** - Creating and configuring prompt starters

### Reference
- **[Architecture Overview](architecture/overview.md)** - Understanding the framework structure
- **[Troubleshooting Guide](troubleshooting.md)** - Common issues and solutions
- **[Running Demos](running-demos.md)** - How to run the demo applications

---

## 🧪 Example Apps

For complete information about example apps and how to run them, see:
- **[Running Demos](running-demos.md)** - Complete guide to running demo applications
- **[Documentation Index](README.md#-example-apps)** - Example apps overview

**Quick start:**
```bash
# iOS Swift example
cd demo-apps/iOS/Simple && make run

# iOS Objective-C example
cd demo-apps/iOS/SimpleObjC && make run

# Android example
cd demo-apps/Android && make run
```

---

## ✨ What You Get

### Core Features
- ✅ **ChatKitCoordinator** - Safe runtime lifecycle management
- ✅ **ChatKitConversationManager** - Optional multi-conversation tracking
- ✅ **NeuronRuntime** - AI agent orchestration
- ✅ **Conversation API** - Session management and messaging
- ✅ **Persistent Storage** - Automatic conversation persistence (convstore)
- ✅ **Reactive Updates** - Combine publishers for UI binding

### UI Components
- ✅ **ChatKitConversationViewController** - Ready-made chat UI component
- ✅ **ChatKitConversationListViewController** - Ready-made conversation list component
- ✅ **Message Bubbles** - User and agent message rendering
- ✅ **Input Composer** - Rich text input with attachments
- ✅ **Typing Indicators** - Real-time typing feedback
- ✅ **Customizable Themes** - Light/dark mode support

### Optional Conveniences
- ✅ **ConversationManager** - Track multiple sessions automatically
- ✅ **ConversationRecord** - Lightweight metadata model
- ✅ **Auto-persistence** - Saves conversations to convstore
- ✅ **Auto-titling** - Uses first user message as title
- ✅ **Reactive list** - Publisher for conversation updates

---

## 🌐 Protocol & Convention Support

ChatKit provides comprehensive support for modern AI agent protocols and UI conventions, enabling seamless integration with the broader AI ecosystem.

### 🤖 AG-UI Protocol Support

ChatKit includes full **AG-UI (Agent UI) protocol** support through NeuronKit, enabling you to build intelligent copilot applications compatible with AG-UI servers (equivalent to CopilotKit for web).

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

### 🎨 OpenAI Apps SDK Bridge

ChatKit includes an **OpenAI Bridge** that provides compatibility with **OpenAI Apps SDK widgets**, enabling you to use widgets designed for OpenAI's chatkit-js without modification.

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

### 🌐 MCP-UI Support

ChatKit provides comprehensive support for **MCP-UI (Model Context Protocol UI)**, enabling native iOS rendering of interactive web-based UI components from MCP servers.

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

### 📊 Protocol Comparison

| Feature | AG-UI | OpenAI Bridge | MCP-UI |
|---------|-------|---------------|--------|
| **Purpose** | Network protocol for agent communication | Widget compatibility layer | UI component rendering |
| **API Style** | SSE + HTTP POST | Promise-based (`window.openai`) | Fire-and-forget (`window.mcpUI`) |
| **State Management** | Conversation-level | Widget-level (`setState`/`getState`) | Manual (in widget) |
| **Tool Calls** | Full consent flow via Sandbox | Promise-based with responses | Fire-and-forget |
| **Text Streaming** | ✅ Real-time incremental | N/A | N/A |
| **Multi-Session** | ✅ Yes | N/A | N/A |
| **Best For** | Agent orchestration & communication | OpenAI Apps SDK widgets | MCP-UI ecosystem widgets |

**Integration:** All three conventions work seamlessly together in ChatKit. AG-UI handles agent communication, while widgets are automatically rendered using either the OpenAI Bridge or MCP-UI support depending on the widget type.

---

## 🏗️ API Levels

ChatKit provides multiple API levels to suit different needs:

### High-Level APIs (Recommended)
Ready-made components for rapid development (20-30 lines for basic chat):
- `ChatKitCoordinator` - Runtime lifecycle management
- `ChatKitConversationViewController` - Complete chat UI
- `ChatKitConversationListViewController` - Conversation list UI

**Best for**: Most applications, standard chat UI, rapid development

### Low-Level APIs (Advanced)
Direct access for maximum flexibility (200+ lines, more control):
- Direct runtime access
- Manual UI binding
- Custom implementations

**Best for**: Custom UI requirements, specialized layouts

### Provider Mechanism
Customize framework behavior without modifying code:
- Context Providers - Attach location, calendar, etc.
- ASR Providers - Custom speech recognition
- Title Generation Providers - Custom conversation titles

**📖 For complete details**: See the [API Levels Guide](api-levels.md) for when to use each level and complete examples.

---

## 📦 Installation

ChatKit supports multiple installation methods. For complete installation instructions, see the [Integration Guide](integration-guide.md).

**Quick install with Swift Package Manager:**
```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
]
```

**Also supports**: CocoaPods, XCFramework, and XcodeGen. See [Integration Guide](integration-guide.md) for all options.

---

## 🎯 Best Practices

### ✅ DO

1. **Initialize coordinator once at app launch**
   ```swift
   // In SceneDelegate or AppDelegate
   let coordinator = ChatKitCoordinator(config: config)
   ```

2. **Use high-level APIs for standard chat UI**
   ```swift
   // Create conversation
   let (record, conversation) = try await coordinator.startConversation(...)
   
   // Show ready-made chat UI
   let chatVC = ChatKitConversationViewController(
       record: record,
       conversation: conversation,
       coordinator: coordinator,
       configuration: .default
   )
   ```

3. **Use ConversationManager for multi-session apps**
   ```swift
   let manager = ChatKitConversationManager()
   manager.attach(runtime: coordinator.runtime)
   ```

4. **Observe reactively with Combine**
   ```swift
   manager.recordsPublisher
       .sink { records in /* update UI */ }
       .store(in: &cancellables)
   ```

5. **Embed components in any container**
   ```swift
   // Navigation, sheet, drawer, tab - all work!
   navigationController?.pushViewController(chatVC, animated: true)
   ```

### ❌ DON'T

1. **Don't create conversations at app launch**
   ```swift
   // ❌ BAD: Too early, user hasn't requested it
   func application(...) -> Bool {
       let coordinator = ChatKitCoordinator(config: config)
       let conversation = try await coordinator.startConversation(...) // Don't!
   }
   ```

2. **Don't create multiple coordinators**
   ```swift
   // ❌ BAD: Creates multiple runtimes
   func newChat() {
       let coordinator = ChatKitCoordinator(config: config) // Don't!
   }
   ```

3. **Don't forget to store coordinator**
   ```swift
   // ❌ BAD: Gets deallocated immediately
   func setup() {
       let coordinator = ChatKitCoordinator(config: config)
       // Oops, released when function returns
   }
   ```

4. **Don't use low-level APIs unless necessary**
   ```swift
   // ❌ BAD: Unnecessary complexity for standard use case
   let hosting = ChatHostingController()
   let adapter = ChatKitAdapter(chatView: hosting.chatView)
   conversation.bindUI(adapter) // Too verbose!
   
   // ✅ GOOD: Use high-level component
   let chatVC = ChatKitConversationViewController(...) // Simple!
   ```

5. **Don't edit generated Xcode projects**
   ```swift
   // ❌ BAD: Changes lost on regeneration
   // Edit .xcodeproj directly
   
   // ✅ GOOD: Edit project.yml, then regenerate
   // make generate
   ```

---

## 🔧 Troubleshooting

Common issues and solutions are documented in the [Troubleshooting Guide](troubleshooting.md).

**Quick fixes:**
- `ChatKitCoordinator` not found → Update to v0.7.4 or later
- Conversations not persisting → Use `.persistent` storage
- Framework not found → Check [Integration Guide](integration-guide.md) for build settings

**📖 For complete troubleshooting**: See the [Troubleshooting Guide](troubleshooting.md) for all common issues and solutions.

---

## 📖 Learning Path

Follow this progressive path to master ChatKit:

1. **Quick Start** → [Quick Start Guide](quick-start.md) - Minimal skeleton code (5 minutes)
2. **Learn the Basics** → [Getting Started Guide](getting-started.md) - Detailed walkthrough
3. **Understand APIs** → [API Levels Guide](api-levels.md) - High-level vs low-level APIs
4. **Build Features** → [Swift Developer Guide](guides/developer-guide.md) or [Objective-C Developer Guide](guides/objective-c-guide.md)
5. **Customize & Embed** → [Component Embedding Guide](component-embedding.md)
6. **Set Up Builds** → [Build Tooling Guide](build-tooling.md)
7. **Study Examples** → See [Running Demos](running-demos.md) for demo apps

**📑 For complete navigation**: See the [Documentation Index](README.md) for all guides organized by topic.

---

## 🤝 Contributing & Support

For contributing guidelines and support resources, see the [Documentation Index](README.md#-contributing).

**Quick links:**
- **Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)
- **Examples**: See [Running Demos](running-demos.md) for demo applications

---

## 🔧 Build Tooling

ChatKit examples use standardized build tools for reproducibility (XcodeGen, Makefile, project.yml).

**📖 For complete instructions**: See the [Build Tooling Guide](build-tooling.md) for reproducible builds.

**Quick start**:
```bash
cd demo-apps/iOS/Simple
make generate  # Generate Xcode project
make run       # Build and run on simulator
```

---

**Ready to build?** Start with the [Quick Start Guide](quick-start.md) →

---

Made by the FinClip team
