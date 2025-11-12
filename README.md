# FinClip ChatKit

**The conversational AI SDK for iOS apps.**

FinClip ChatKit provides a complete framework for building AI-powered chat experiences in your iOS applications. From simple single-agent conversations to complex multi-session apps with conversation history.

---

## 🚀 Quick Start

### 5-Minute Setup

**1. Add dependency** to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
]
```

**2. Initialize runtime at app launch:**

```swift
import FinClipChatKit

// In AppDelegate
let config = NeuronKitConfig(
    serverURL: URL(string: "https://your-agent-server.com")!,
    deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
    userId: "user-123",
    storage: .persistent
)
let coordinator = ChatKitCoordinator(config: config)
```

**3. Create conversation when user requests it:**

```swift
// When user taps "New Chat" button
let conversation = coordinator.runtime.openConversation(
    sessionId: UUID(),
    agentId: yourAgentId
)

// Show chat UI
let chatVC = ChatViewController(conversation: conversation)
```

That's it! You now have a working AI chat app.

---

## 📚 Documentation

Start with the right guide for your needs:

### For Beginners
- **[Getting Started](docs/getting-started.md)** - Build your first chat app in 10 minutes

### For Intermediate Developers
- **[Developer Guide](docs/developer-guide.md)** - Comprehensive guide covering:
  - Part 1: Simple chat app (beginner)
  - Part 2: Multiple conversations (intermediate)
  - Part 3: Conversation history UI (advanced)

### For Reference
- **[Architecture Overview](docs/architecture/overview.md)** - Understanding the framework structure
- **[Customize UI Guide](docs/how-to/customize-ui.md)** - Styling and theming
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions
- **[Integration Guide](docs/integration-guide.md)** - SPM, CocoaPods, deployment

---

## 🧪 Example Apps

Explore fully working examples in `demo-apps/iOS/`:

### AI-Bank
A banking-themed demo showing multi-conversation management.

```bash
cd demo-apps/iOS/AI-Bank
make run
```

**What it demonstrates:**
- Multiple conversation sessions
- Conversation history
- Persistent storage

**Note:** This example includes app-level patterns (agent management, testing modes) that are NOT part of the SDK.

### Smart-Gov
A government services demo with conversation management.

```bash
cd demo-apps/iOS/Smart-Gov
make run
```

**What it demonstrates:**
- Multi-session support
- Conversation persistence
- List UI implementation

**Note:** Agent selection and testing modes shown here are app design choices, not SDK features.

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
- ✅ **ChatViewController** - Full-featured chat interface
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

## 🏗️ Architecture

ChatKit is a composite framework that bundles:

- **FinClipChatKit** - Main framework and coordinator
- **NeuronKit** - AI orchestration layer
- **ConvoUI** - UI components and themes
- **SandboxSDK** - Security and sandboxing
- **convstore** - Conversation persistence

```
Your App
  └─ ChatKitCoordinator (initialize once at app launch)
      └─ NeuronRuntime (core orchestration)
          └─ Conversations (created on user action)
```

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
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
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
3. Select version: `0.3.1` or later

### CocoaPods

```ruby
pod 'ChatKit', '~> 0.3.1'
```

Then run:
```bash
pod install
```

---

## 🎯 Best Practices

### ✅ DO

1. **Initialize runtime once at app launch**
   ```swift
   // In AppDelegate
   chatCoordinator = ChatKitCoordinator(config: config)
   ```

2. **Create conversations when user requests them**
   ```swift
   // When user taps "New Chat"
   let conversation = coordinator.runtime.openConversation(...)
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

5. **Clean up resources**
   ```swift
   conversation.unbindUI() // Before destroying UI
   manager.deleteConversation(sessionId) // To remove permanently
   ```

### ❌ DON'T

1. **Don't create conversations at app launch**
   ```swift
   // ❌ BAD: Too early, user hasn't requested it
   func application(...) -> Bool {
       let coordinator = ChatKitCoordinator(config: config)
       let conversation = coordinator.runtime.openConversation(...) // Don't!
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

4. **Don't block main thread**
   ```swift
   // ❌ BAD: Persistence is async
   manager.createConversation(...)
   waitForIt() // Don't!
   
   // ✅ GOOD: Happens automatically in background
   manager.createConversation(...) // Just use it
   ```

5. **Don't leak conversations**
   ```swift
   // ✅ GOOD: Always unbind in deinit
   deinit {
       conversation?.unbindUI()
   }
   ```

---

## 🔧 Troubleshooting

### ChatKitCoordinator not found
**Solution**: Update to v0.3.1 or later
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
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

1. **Start Simple** → [Getting Started](docs/getting-started.md)
   - Build your first chat app in 10 minutes

2. **Understand Core Concepts** → [Developer Guide Part 1](docs/developer-guide.md#part-1-getting-started)
   - Runtime vs Conversation
   - When to create what

3. **Add Multiple Conversations** → [Developer Guide Part 2](docs/developer-guide.md#part-2-managing-multiple-conversations)
   - Using ConversationManager
   - Reactive updates

4. **Build History UI** → [Developer Guide Part 3](docs/developer-guide.md#part-3-building-a-conversation-list-ui)
   - Conversation list
   - Resume and delete

5. **Study Examples** → `demo-apps/iOS/`
   - AI-Bank and Smart-Gov demos
   - App-level patterns

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

- ✅ Safe runtime lifecycle management with `ChatKitCoordinator`
- ✅ When to initialize runtime vs create conversations
- ✅ Building simple single-conversation apps
- ✅ Managing multiple conversations with `ConversationManager`
- ✅ Implementing conversation history UI
- ✅ Persisting conversations with convstore
- ✅ Reactive UI updates with Combine
- ✅ Best practices and common pitfalls

---

**Ready to build?** Start with [Getting Started](docs/getting-started.md) →

---

Made with ❤️ by the FinClip team
