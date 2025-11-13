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

### 5-Minute Setup

**1. Add dependency** to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
]
```

**2. Initialize coordinator at app launch:**

```swift
import UIKit
import FinClipChatKit

// In SceneDelegate or AppDelegate
let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
    .withUserId("demo-user")
let coordinator = ChatKitCoordinator(config: config)
```

**3. Create conversation and show chat UI:**

```swift
// When user taps "New Chat" button
Task { @MainActor in
    let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
    let (record, conversation) = try await coordinator.startConversation(
        agentId: agentId,
        title: nil,
        agentName: "My Agent"
    )
    
    // Show ready-made chat UI
    let chatVC = ChatKitConversationViewController(
        record: record,
        conversation: conversation,
        coordinator: coordinator,
        configuration: .default
    )
    
    navigationController?.pushViewController(chatVC, animated: true)
}
```

That's it! You now have a working AI chat app with persistent storage and full-featured UI.

**📖 For detailed examples**: See [Quick Start Guide](docs/quick-start.md) for Swift and Objective-C skeleton code.

---

## 📚 Documentation

Start with the right guide for your needs:

### Quick Start
- **[Quick Start Guide](docs/quick-start.md)** - Minimal skeleton code (Swift & Objective-C) - **Start here!**
- **[Getting Started Guide](docs/getting-started.md)** - Detailed walkthrough with explanations

### Core Guides

#### Swift
- **[Swift Developer Guide](docs/guides/developer-guide.md)** - Comprehensive Swift guide from beginner to expert

#### Objective-C
- **[Objective-C Developer Guide](docs/guides/objective-c-guide.md)** - Complete Objective-C guide with API reference

#### Shared Concepts
- **[API Levels Guide](docs/api-levels.md)** - Understanding high-level vs low-level APIs
- **[Component Embedding Guide](docs/component-embedding.md)** - Embed components in sheets, drawers, tabs (Swift & Objective-C)
- **[Build Tooling Guide](docs/build-tooling.md)** - Reproducible builds with Makefile and XcodeGen

### Reference
- **[Architecture Overview](docs/architecture/overview.md)** - Understanding the framework structure
- **[Customize UI Guide](docs/how-to/customize-ui.md)** - Styling and theming
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions
- **[Integration Guide](docs/integration-guide.md)** - SPM, CocoaPods, deployment

**📑 [Full Documentation Index](docs/README.md)** - Complete navigation and learning paths

---

## 🧪 Example Apps

Explore fully working examples in `demo-apps/iOS/`:

### Simple (Swift) - Recommended
Demonstrates high-level APIs with minimal code.

```bash
cd demo-apps/iOS/Simple
make run
```

**What it demonstrates:**
- High-level APIs (`ChatKitCoordinator`, `ChatKitConversationViewController`)
- Drawer-based navigation pattern
- Component embedding
- Standard build tooling (Makefile, XcodeGen)

**See**: [Simple README](demo-apps/iOS/Simple/README.md)

### SimpleObjC (Objective-C)
Objective-C version using high-level APIs.

```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**What it demonstrates:**
- Objective-C high-level APIs (`CKTChatKitCoordinator`, `ChatKitConversationViewController`)
- Navigation-based flow
- Remote dependency usage

**See**: [SimpleObjC README](demo-apps/iOS/SimpleObjC/README.md)

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
Ready-made components for rapid development:
- `ChatKitCoordinator` - Runtime lifecycle management
- `ChatKitConversationViewController` - Complete chat UI
- `ChatKitConversationListViewController` - Conversation list UI
- Minimal code (20-30 lines for basic chat)

**Best for**: Most applications, standard chat UI, rapid development

**See**: [API Levels Guide](docs/api-levels.md#high-level-apis-recommended) | [Simple Demo](demo-apps/iOS/Simple/)

### Low-Level APIs (Advanced)
Direct access for maximum flexibility:
- Direct runtime access
- Manual UI binding
- Custom implementations
- More code (200+ lines), more control

**Best for**: Custom UI requirements, specialized layouts

**See**: [API Levels Guide](docs/api-levels.md#low-level-apis-advanced)

### Provider Mechanism
Customize framework behavior without modifying code:
- Context Providers - Attach location, calendar, etc.
- ASR Providers - Custom speech recognition
- Title Generation Providers - Custom conversation titles

**See**: [API Levels Guide](docs/api-levels.md#provider-mechanism)

---

## 📦 Installation

### Swift Package Manager (Recommended)

**Option 1: Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)
```

**Option 2: Xcode**

1. File → Add Package Dependencies
2. Enter: `https://github.com/Geeksfino/finclip-chatkit.git`
3. Select version: `0.6.1` or later

### CocoaPods

```ruby
pod 'ChatKit', :podspec => 'https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/ChatKit.podspec'
```

Then run:
```bash
pod install
```

> **Note**: We use a direct podspec URL because the "ChatKit" name on CocoaPods trunk is occupied by a different project.

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

### ChatKitCoordinator not found
**Solution**: Update to v0.6.1 or later
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
```

### Conversations not persisting
**Solution**: Use `.persistent` storage
```swift
NeuronKitConfig(..., storage: .persistent)
```

### More help
See the full [Troubleshooting Guide](docs/troubleshooting.md).

---

## 📖 Learning Path

Follow this progressive path to master ChatKit:

1. **Quick Start** → [Quick Start Guide](docs/quick-start.md)
   - Minimal skeleton code (5 minutes)
   - Swift and Objective-C examples

2. **Learn the Basics** → [Getting Started Guide](docs/getting-started.md)
   - Detailed walkthrough
   - Key concepts explained

3. **Understand APIs** → [API Levels Guide](docs/api-levels.md)
   - High-level vs low-level APIs
   - When to use each

4. **Build Features**
   - **Swift**: [Swift Developer Guide](docs/guides/developer-guide.md) - Multiple conversations, history, advanced patterns
   - **Objective-C**: [Objective-C Developer Guide](docs/guides/objective-c-guide.md) - Multiple conversations, list UI, API reference

5. **Customize & Embed** → [Component Embedding Guide](docs/component-embedding.md)
   - Embed in sheets, drawers, tabs
   - Custom container patterns

6. **Set Up Builds** → [Build Tooling Guide](docs/build-tooling.md)
   - Reproducible builds
   - Makefile and XcodeGen

7. **Study Examples** → `demo-apps/iOS/Simple/` and `demo-apps/iOS/SimpleObjC/`
   - Complete working examples
   - High-level API patterns

---

## 🤝 Contributing

We welcome contributions! Please:

1. Open an issue for bugs or feature requests
2. Submit pull requests with improvements
3. Update documentation for new features
4. Add tests for new functionality

---

## 📄 License

See [LICENSE](LICENSE) for details.

---

## 🆘 Support

- **Documentation**: `docs/`
- **Examples**: `demo-apps/iOS/`
- **Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)

---

## 🎓 What You'll Learn

From the examples and documentation:

- ✅ High-level APIs for rapid development
- ✅ Safe runtime lifecycle management with `ChatKitCoordinator`
- ✅ Ready-made UI components (`ChatKitConversationViewController`, `ChatKitConversationListViewController`)
- ✅ Component embedding in various containers (navigation, sheets, drawers, tabs)
- ✅ Managing multiple conversations with `ChatKitConversationManager`
- ✅ Provider mechanisms (context, ASR, title generation)
- ✅ Reproducible builds with Makefile and XcodeGen
- ✅ Best practices and common pitfalls

---

## 🔧 Build Tooling

ChatKit examples use standardized build tools for reproducibility:

- **XcodeGen** - Generate Xcode projects from YAML
- **Makefile** - Standardized build commands
- **project.yml** - Version-controlled project configuration

**See**: [Build Tooling Guide](docs/build-tooling.md) for complete instructions.

**Quick start**:
```bash
cd demo-apps/iOS/Simple
make generate  # Generate Xcode project
make run       # Build and run on simulator
```

---

**Ready to build?** Start with [Quick Start Guide](docs/quick-start.md) →

---

Made by the FinClip team
