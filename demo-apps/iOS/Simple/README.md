# Simple Demo App

A simple demonstration app for ChatKit SDK, showcasing conversational AI capabilities with persistent storage, multi-instance management, and SDK extensibility through custom providers.

> **📘 Important: SDK Extensibility**  
>  
> This example demonstrates how to **extend ChatKit SDK** with custom providers:
> - **Context Providers** - Inject custom context (calendar, location, etc.) into conversations
> - **Speech-to-Text Providers** - Register custom speech recognition providers
> - **RuntimeCoordinator** - App-specific wrapper around SDK
>  
> **The ChatKit SDK provides:**
> - `ChatKitCoordinator` - Safe runtime lifecycle management  
> - `ChatKitConversationManager` - Optional multi-conversation tracking  
> - `NeuronRuntime` and `Conversation` APIs - Core SDK functionality  
> - **Extensibility APIs** - Register context providers and speech-to-text providers
>  
> This demo shows how to extend the SDK with custom providers.  
> See the [Developer Guide](../../docs/developer-guide.md) for SDK-only usage patterns.

## 🎯 Overview

Simple demonstrates:
- ✅ **ChatKit Integration** - Complete setup of NeuronKit + ConvoUI
- ✅ **Persistent Storage** - Conversation history using CoreData
- ✅ **Multi-Instance Management** - Multiple simultaneous conversations
- ✅ **SDK Extensibility** - Custom context providers (Calendar, Location)
- ✅ **Real-time Streaming** - Token-by-token message rendering
- ✅ **Clean Architecture** - Separation of concerns with coordinators

## 📦 Features

### 1. Conversation Management
- **Conversation List** - View all past conversations with metadata
- **Create New** - Start fresh conversations with unique sessions
- **Resume Chat** - Continue historical conversations seamlessly
- **Delete Conversations** - Clean up unwanted history

### 2. SDK Extensibility (Extensions/)
- **Context Providers** - Inject calendar events, location, and custom context into conversations
- **Provider Factory** - Centralized provider registration and management
- **Speech-to-Text** - Register custom speech recognition providers (example pattern)

### 3. Multi-Chat Support
- **Side Drawer** - Navigate between multiple active conversations
- **Dynamic Binding** - Efficient memory usage with bind/unbind pattern
- **Background Conversations** - Keep multiple chats alive simultaneously

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+
- ChatKit SDK (via Swift Package Manager)

### Building the App

```bash
cd demo-apps/iOS/Simple

# Generate Xcode project
make generate

# Open in Xcode
make open

# Or build and run directly
make run
```

The app uses Swift Package Manager to fetch ChatKit from the remote repository.

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
4. In **Fixture Mode**, you'll see a mock agent response stream

### Managing Conversations

- **Resume**: Tap any conversation in the list to continue
- **Delete**: Swipe left on conversation and tap delete
- **Switch**: Use the side drawer to switch between active chats
- **View History**: All messages are persisted and restored

## 🏗️ Architecture

```
Simple/
├── App/
│   ├── App/
│   │   ├── AppDelegate.swift              # App lifecycle
│   │   ├── SceneDelegate.swift            # Scene setup
│   │   ├── ComposerToolsExample.swift     # Composer tools demo
│   │   └── LocalizationHelper.swift       # i18n utilities
│   ├── Models/
│   │   └── ConversationRecord.swift       # Conversation data model
│   ├── Coordinators/
│   │   ├── RuntimeCoordinator.swift       # ChatKit runtime lifecycle
│   │   └── ConversationManager.swift      # Conversation management
│   ├── Extensions/
│   │   ├── ChatContextProviders.swift     # Factory for context providers
│   │   ├── CalendarContextProvider.swift  # SDK Extension: Calendar context
│   │   └── LocationContextProvider.swift  # SDK Extension: Location context
│   └── ViewControllers/
│       ├── ConnectionViewController.swift      # Server connection setup
│       ├── ConversationListViewController.swift # History UI
│       ├── MainChatViewController.swift        # Main container
│       ├── ChatViewController.swift            # Individual chat UI
│       ├── DrawerViewController.swift          # Conversation switcher
│       ├── DrawerContainerViewController.swift # Drawer container
│       └── ConversationPreviewViewController.swift # Preview UI
├── Package.swift                            # Swift Package Manager manifest
├── project.yml                             # XcodeGen configuration
└── Makefile                                # Build automation
```

### Architecture Pattern

This demo follows **Clean Architecture with Coordinator Pattern** for iOS:

**Layer Separation:**
- **App/** - Application lifecycle and bootstrapping
- **Models/** - Data structures and domain entities
- **Coordinators/** - Business logic and runtime management (Coordinator pattern)
- **Extensions/** - SDK extensibility points (Context Providers, STT Providers)
- **ViewControllers/** - Presentation layer (UI)

**Key Principles:**
- ✅ **Separation of Concerns** - Each layer has a single responsibility
- ✅ **Dependency Direction** - UI depends on coordinators, coordinators depend on models
- ✅ **Testability** - Business logic isolated from UI
- ✅ **Extensibility** - Clear SDK extension points in `Extensions/` folder

This structure follows iOS engineering best practices and makes it easy for developers to understand where to add custom providers for SDK extensibility.

### Key Components

**RuntimeCoordinator** (Business Logic Layer)
- Manages NeuronRuntime lifecycle
- Configures network adapters
- Handles runtime initialization and teardown

**ConversationManager** (Business Logic Layer)
- Tracks multiple conversation instances
- Manages bind/unbind lifecycle for ChatKitAdapter
- Provides conversation metadata and state

**SDK Extensions** (`Extensions/`)
- `CalendarContextProvider` - Injects calendar events into conversations
- `LocationContextProvider` - Injects location data into conversations
- `ChatContextProviderFactory` - Centralized provider registration
- Demonstrates extensibility pattern for custom context providers

## 🔌 SDK Extensibility

The `Extensions/` folder demonstrates how to extend ChatKit SDK with custom providers.

### Context Providers

Context providers inject custom data into conversations:

**CalendarContextProvider Example:**
```swift
class CalendarContextProvider: ContextProvider {
    func provideContext() async -> String {
        // Fetch upcoming calendar events
        let events = await fetchCalendarEvents()
        return "Upcoming events: \(events)"
    }
}
```

**Registering Providers:**
```swift
// In ChatContextProviderFactory
static func makeDefaultProviders() -> [FinConvoComposerContextProvider] {
    return [
        ConvoUIContextProviderBridge(provider: LocationContextProvider()),
        ConvoUIContextProviderBridge(provider: CalendarContextProvider())
    ]
}
```

### Speech-to-Text Providers

The same pattern applies for custom speech-to-text providers:
1. Implement the provider protocol
2. Register with ChatKit runtime
3. Inject into ConvoUI components

See `Extensions/` folder for complete examples.

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
- Ensure Package.swift references the correct ChatKit version
- Run `swift package resolve` to fetch dependencies
- Check network connectivity to GitHub

**"Cannot find type 'MockSSEURLProtocol'"**
- Regenerate Xcode project: `make generate`
- Ensure `App/Network` is in project.yml sources

### Runtime Errors

**App crashes on launch**
- Check ChatKit framework is properly resolved
- Verify all embedded frameworks are present
- Review RuntimeCoordinator logs for initialization errors

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

