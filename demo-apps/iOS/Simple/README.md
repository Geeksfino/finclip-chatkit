# Simple Demo App

A demonstration app showcasing ChatKit's **high-level APIs** for rapid development. This app demonstrates how to build a complete chat application with minimal code using ready-made components.

> **📘 Key Focus: High-Level APIs**  
>  
> This example demonstrates ChatKit's **high-level APIs**:
> - `ChatKitCoordinator` - Runtime lifecycle management
> - `ChatKitConversationViewController` - Ready-made chat UI component
> - `ChatKitConversationListViewController` - Ready-made conversation list component
> - Provider customization (context providers, tools)
>  
> **Result**: Complete chat app with **~477 lines of code** in ViewControllers (vs 1000+ with low-level APIs)  
> Uses high-level components to eliminate boilerplate - no custom list/cell implementations needed!

## 🎯 Overview

Simple demonstrates:
- ✅ **High-Level APIs** - Ready-made components for rapid development
- ✅ **Component Embedding** - Drawer-based navigation pattern
- ✅ **Provider Customization** - Context providers (calendar, location)
- ✅ **Persistent Storage** - Automatic conversation persistence
- ✅ **Multi-Conversation Management** - Multiple simultaneous conversations
- ✅ **Build Tooling** - Reproducible builds with Makefile and XcodeGen

## 📦 Features

### 1. High-Level Component Usage

**ChatKitConversationViewController** - Ready-made chat UI:
```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

**ChatKitConversationListViewController** - Ready-made list UI:
```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

### 2. Provider Customization

- **Context Providers** - Calendar and location context
- **Tools Provider** - Custom composer tools
- **Welcome Message** - Customizable welcome message

### 3. Drawer Pattern

- Side drawer with conversation list
- Main chat area
- Seamless switching between conversations

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- XcodeGen (`brew install xcodegen`)
- **Node.js 20+** (for backend server)

### Backend Server Setup

**Important**: This demo requires a running backend server. Start the server first:

```bash
# In a separate terminal window
cd ../../server/agui-test-server
npm install
npm run dev
```

The server will start on `http://localhost:3000`.

**See**: [Server Documentation](../../server/README.md) for detailed server setup, configuration options, and troubleshooting.

### Building the App

```bash
cd demo-apps/iOS/Simple

# Generate Xcode project from project.yml
make generate

# Open in Xcode
make open

# Or build and run directly
make run
```

**Build Tooling**: This app uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) and a Makefile for reproducible builds. See the [Build Tooling Guide](../../docs/build-tooling.md) for details.

### Dependencies

The app uses Swift Package Manager to fetch ChatKit from GitHub:
- **Package**: `https://github.com/Geeksfino/finclip-chatkit.git`
- **Version**: `0.9.0`

## 📱 Using the App

### First Launch

1. App launches with drawer closed
2. Tap the menu button to open drawer
3. Tap "+" to create a new conversation
4. Chat view opens automatically

### Creating a Conversation

1. Tap **"+"** button in drawer
2. **Chat View** opens with empty conversation
3. Type a message and press send
4. Agent responds (requires backend server)

### Managing Conversations

- **Resume**: Tap any conversation in the drawer to switch
- **Delete**: Swipe left on conversation in drawer
- **Search**: Use search bar in drawer to find conversations
- **View History**: All messages are persisted and restored

## 🏗️ Architecture

```
Simple/
├── App/
│   ├── App/
│   │   ├── SceneDelegate.swift            # Initialize ChatKitCoordinator (no connection screen!)
│   │   ├── AppConfig.swift                # App configuration constants
│   │   ├── ComposerToolsExample.swift     # Composer tools demo
│   │   └── LocalizationHelper.swift       # i18n utilities
│   ├── Extensions/
│   │   ├── ChatContextProviders.swift        # Provider factory
│   │   ├── CalendarContextProvider.swift     # Calendar context provider
│   │   └── LocationContextProvider.swift     # Location context provider
│   └── ViewControllers/                      # Just 4 files - 477 lines total!
│       ├── DrawerContainerViewController.swift    # Drawer container (155 lines)
│       ├── DrawerViewController.swift             # Thin wrapper around ChatKitConversationListViewController (64 lines)
│       ├── MainChatViewController.swift            # Main chat container (220 lines)
│       └── ChatViewController.swift               # Thin wrapper around ChatKitConversationViewController (38 lines)
├── project.yml                             # XcodeGen configuration
└── Makefile                                # Build automation
```

### Key Architecture Points

**Maximum Use of High-Level APIs**:
- `DrawerViewController` - 64-line thin wrapper around `ChatKitConversationListViewController`
- `ChatViewController` - 38-line thin wrapper around `ChatKitConversationViewController`
- **Zero custom list/cell implementations** - framework handles everything
- **No connection screen** - coordinator initialized directly in SceneDelegate

**What You DON'T Need to Implement**:
- ❌ Custom table view cells for conversations
- ❌ Custom search/filter logic
- ❌ Custom swipe-to-delete handlers
- ❌ Custom empty state views
- ❌ Connection management UI

**Container-Agnostic Design**:
- Drawer pattern demonstrates flexibility
- Components work in navigation stacks, sheets, drawers, tabs
- Just configure and present - framework handles the rest

## 💡 Key Code Patterns

### Initialization

```swift
// In SceneDelegate
let config = NeuronKitConfig.default(serverURL: AppConfig.defaultServerURL)
    .withUserId(AppConfig.defaultUserId)
let coordinator = ChatKitCoordinator(config: config)
```

### Creating Conversation

```swift
let (record, conversation) = try await coordinator.startConversation(
    agentId: AppConfig.defaultAgentId,
    title: nil,
    agentName: AppConfig.defaultAgentName
)
```

### Showing Chat UI

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Showing List UI

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

## 🔧 Configuration

### ChatKitConversationConfiguration

```swift
var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "Hello! How can I help?" }
config.toolsProvider = { ComposerToolsExample.createExampleTools() }
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        ChatContextProviderFactory.makeDefaultProviders()
    }
}
```

### ChatKitConversationListConfiguration

```swift
var config = ChatKitConversationListConfiguration.default
config.headerTitle = "Simple"
config.showSearchBar = true
config.showNewButton = true
config.enableSwipeToDelete = true
```

## 📚 Learning Resources

### Documentation

- **[Quick Start Guide](../../docs/quick-start.md)** - Minimal skeleton code
- **[API Levels Guide](../../docs/api-levels.md)** - High-level vs low-level APIs
- **[Component Embedding Guide](../../docs/component-embedding.md)** - Embedding patterns
- **[Build Tooling Guide](../../docs/build-tooling.md)** - Makefile and XcodeGen

### Related Examples

- **[SimpleObjC](../SimpleObjC)** - Objective-C version using high-level APIs

## 🐛 Troubleshooting

### Build Errors

**"XcodeGen not found"**
- Install: `brew install xcodegen`

**"Module 'ChatKit' not found"**
- Run `make generate` to regenerate project
- Check `project.yml` has correct package dependency

### Runtime Errors

**"Failed to create conversation"**
- Check server URL in `AppConfig.swift`
- Ensure backend server is running

**"Messages not persisting"**
- Persistent storage is enabled by default
- Check CoreData container initialization

## 🤝 Contributing

Found an issue or want to add features? See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../../../LICENSE) for details

---

**Made with ❤️ by the FinClip team**
