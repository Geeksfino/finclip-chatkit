# MyChatGPT Example App

A comprehensive demonstration app for ChatKit SDK, showcasing conversational AI capabilities with persistent storage, multi-instance management, and fixture-based testing.

## 🎯 Overview

MyChatGPT demonstrates:
- ✅ **ChatKit Integration** - Complete setup of NeuronKit + ConvoUI
- ✅ **Persistent Storage** - Conversation history using CoreData
- ✅ **Multi-Instance Management** - Multiple simultaneous conversations
- ✅ **Fixture Mode** - Mock backend for testing without a server
- ✅ **Real-time Streaming** - Token-by-token message rendering
- ✅ **Clean Architecture** - Separation of concerns with coordinators

## 📦 Features

### 1. Conversation Management
- **Conversation List** - View all past conversations with metadata
- **Create New** - Start fresh conversations with unique sessions
- **Resume Chat** - Continue historical conversations seamlessly
- **Delete Conversations** - Clean up unwanted history

### 2. Connection Modes
- **Fixture Mode** - Uses mock SSE responses for local testing
- **Remote Mode** - Connects to actual AG-UI compatible server (coming soon)

### 3. Multi-Chat Support
- **Side Drawer** - Navigate between multiple active conversations
- **Dynamic Binding** - Efficient memory usage with bind/unbind pattern
- **Background Conversations** - Keep multiple chats alive simultaneously

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+
- ChatKit framework built (from repository root)

### Building the Framework

From the repository root:

```bash
# Build ChatKit.xcframework (requires macOS)
make build

# Or use pre-built framework if available
# Place it in .dist/ChatKit.xcframework
```

### Building the Example

```bash
cd Examples/MyChatGPT

# Generate Xcode project
make generate

# Open in Xcode
make open

# Or build and run directly
make run
```

## 📱 Using the App

### First Launch

1. **Connection Screen** appears
2. **Fixture Mode** is pre-selected (recommended for first run)
3. Tap **"Connect"** to initialize the runtime
4. **Conversation List** appears (empty on first launch)

### Creating a Conversation

1. Tap **"+"** button in conversation list
2. **Chat View** opens with empty conversation
3. Type a message and press send
4. In **Fixture Mode**, you'll see a mock agent response stream in

### Managing Conversations

- **Resume**: Tap any conversation in the list to continue
- **Delete**: Swipe left on conversation and tap delete
- **Switch**: Use the side drawer to switch between active chats
- **View History**: All messages are persisted and restored

## 🏗️ Architecture

```
MyChatGPT/
├── App/
│   ├── App/
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift
│   ├── Coordinators/
│   │   ├── RuntimeCoordinator.swift       # NeuronKit lifecycle
│   │   └── ConversationManager.swift      # Multi-instance management
│   ├── ViewControllers/
│   │   ├── ConnectionViewController.swift  # Server connection setup
│   │   ├── ConversationListViewController.swift  # History UI
│   │   ├── MainChatViewController.swift    # Main container
│   │   ├── ChatViewController.swift        # Individual chat UI
│   │   ├── DrawerViewController.swift      # Conversation switcher
│   │   └── DrawerContainerViewController.swift  # Drawer container
│   ├── Models/
│   │   └── ConversationRecord.swift        # Conversation metadata
│   └── Network/
│       ├── MockSSEURLProtocol.swift        # Mock SSE responses
│       └── AGUIFixtures.swift              # Fixture data loader
├── Resources/
│   └── Fixtures/
│       └── text_message_sequence.json      # Mock AG-UI events
└── project.yml                             # XcodeGen configuration
```

### Key Components

**RuntimeCoordinator**
- Manages NeuronRuntime lifecycle
- Configures network adapters (fixture or remote)
- Handles runtime initialization and teardown

**ConversationManager**
- Tracks multiple conversation instances
- Manages bind/unbind lifecycle for ChatKitAdapter
- Provides conversation metadata and state

**MockSSEURLProtocol**
- Intercepts URLSession requests for fixture mode
- Replays pre-recorded AG-UI events as SSE stream
- Simulates realistic timing and streaming

## 🧪 Fixture Mode

Fixture mode allows testing without a backend server by replaying pre-recorded events.

### How It Works

1. **MockSSEURLProtocol** intercepts network requests
2. Loads events from `text_message_sequence.json`
3. Streams events as Server-Sent Events (SSE)
4. Simulates realistic timing between events

### Fixture Data Format

```json
{
  "events": [
    {
      "event": "RUN_STARTED",
      "data": { "runId": "...", "agentId": "..." }
    },
    {
      "event": "TEXT_MESSAGE_START",
      "data": { "messageId": "..." }
    },
    {
      "event": "TEXT_MESSAGE_CONTENT",
      "data": { "content": "Hello, " }
    }
  ]
}
```

### Adding Custom Fixtures

1. Create JSON file in `Resources/Fixtures/`
2. Follow AG-UI event format
3. Update `AGUIFixtures.swift` to load your fixture
4. Select your fixture in connection screen

## 🔧 Configuration

### Storage Mode

In `RuntimeCoordinator.swift`:

```swift
// Use persistent storage (recommended)
config = NeuronKitConfig(
    serverURL: url,
    deviceId: deviceId,
    userId: userId,
    storage: .persistent  // Saves to CoreData
)

// Or use in-memory storage (for testing)
storage: .inMemory  // Lost on app restart
```

### Network Adapter

In `RuntimeCoordinator.swift`:

```swift
// Fixture mode (mock responses)
let adapter = AGUI_Adapter(
    baseEventURL: fixtureURL,
    connectionMode: .postStream
)
configureFixtureMode(adapter: adapter)

// Remote mode (real server)
let adapter = AGUI_Adapter(
    baseEventURL: realServerURL,
    connectionMode: .postStream
)
runtime.setNetworkAdapter(adapter)
```

## 🐛 Troubleshooting

### Build Errors

**"Module 'ChatKit' not found"**
- Ensure ChatKit.xcframework is built: `make build` from repo root
- Check framework is in `.dist/ChatKit.xcframework`

**"Cannot find type 'MockSSEURLProtocol'"**
- Regenerate Xcode project: `make generate`
- Ensure `App/Network` is in project.yml sources

### Runtime Errors

**App crashes on launch**
- Check ChatKit.xcframework is properly signed
- Verify all embedded frameworks are present
- Run `make clean && make build` to rebuild

**Fixture mode not working**
- Verify `text_message_sequence.json` exists in Resources/Fixtures
- Check fixture is included in project.yml resources
- Review RuntimeCoordinator logs for loading errors

**Messages not persisting**
- Ensure storage mode is `.persistent`
- Check CoreData container initialization
- Review NeuronRuntime configuration

## 📚 Learning Resources

### Code Examples

**Creating a Runtime**
```swift
import ChatKit

let runtime = ChatKitSDK.createRuntime(
    serverURL: URL(string: "wss://your-server.com")!,
    userId: "user-123"
)
```

**Starting a Conversation**
```swift
let chatView = FinConvoChatView()
let (conversation, adapter) = runtime.startChat(with: chatView)
```

**Managing Multiple Conversations**
```swift
let manager = ConversationManager()
let conv1 = manager.createConversation(runtime: runtime)
let conv2 = manager.createConversation(runtime: runtime)
manager.switchTo(conv1)  // Binds conv1, unbinds conv2
```

## 🤝 Contributing

Found an issue or want to add features? See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../../LICENSE) for details

---

**Made with ❤️ by the FinClip team**
