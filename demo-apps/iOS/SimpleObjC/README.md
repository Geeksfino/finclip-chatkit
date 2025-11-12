# SimpleObjC Demo App

Objective-C demonstration app showcasing ChatKit's **high-level Objective-C APIs** for rapid development. This app demonstrates how to build a complete chat application in Objective-C with minimal code using ready-made components.

> **📘 Key Focus: High-Level Objective-C APIs**  
>  
> This example demonstrates ChatKit's **high-level Objective-C APIs**:
> - `CKTChatKitCoordinator` - Runtime lifecycle management (no wrapper needed!)
> - `ChatKitConversationViewController` - Ready-made chat UI component (ObjC-compatible)
> - `ChatKitConversationListViewController` - Ready-made conversation list component (ObjC-compatible)
> - Provider customization support
>  
> **Result**: Complete Objective-C chat app with **~218 lines of code** in key files  
> Uses high-level components directly - no custom wrappers or boilerplate!

## 🎯 Overview

SimpleObjC demonstrates:
- ✅ **High-Level Objective-C APIs** - Ready-made components for ObjC developers
- ✅ **Remote Binary Dependency** - Uses ChatKit from GitHub (version 0.6.1)
- ✅ **Navigation-Based Flow** - Standard iOS navigation pattern
- ✅ **Persistent Storage** - Automatic conversation persistence
- ✅ **Multi-Conversation Management** - Multiple simultaneous conversations
- ✅ **Build Tooling** - Reproducible builds with Makefile and XcodeGen

## 📦 Features

### 1. High-Level Component Usage

**ChatKitConversationViewController** - Ready-made chat UI (ObjC-compatible):
```objc
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];
```

**ChatKitConversationListViewController** - Ready-made list UI (ObjC-compatible):
```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              configuration:config];
```

### 2. Objective-C Coordinator

**CKTChatKitCoordinator** - Objective-C wrapper:
```objc
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                       userId:@"demo-user"
                                                                     deviceId:nil];
config.storageMode = CKTStorageModePersistent;
CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

### 3. Conversation Management

- Create conversations via coordinator
- List conversations with search
- Resume and delete conversations
- Automatic persistence

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- iOS 16.0+
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
cd demo-apps/iOS/SimpleObjC

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
- **Version**: `0.6.1`

The framework is automatically resolved as a remote binary dependency when you build the project.

## 📱 Using the App

### First Launch

1. **Connection Screen** appears
2. Tap **"Connect"** to initialize the coordinator
3. **Conversation List** appears (empty on first launch)

### Creating a Conversation

1. Tap **"+"** button in conversation list
2. **Chat View** opens with empty conversation
3. Type a message and press send
4. Agent responds (requires backend server)

### Managing Conversations

- **Resume**: Tap any conversation in the list to continue
- **Delete**: Swipe left on conversation and tap delete
- **Search**: Use search bar to find conversations
- **View History**: All messages are persisted and restored

## 🏗️ Architecture

```
SimpleObjC/
├── App/
│   ├── AppDelegate.h/m          # App delegate
│   ├── SceneDelegate.h/m        # Scene delegate (initializes coordinator directly)
│   ├── ViewControllers/         # Just 2 files - thin wrappers!
│   │   ├── ConversationListViewController.h/m  # Embeds ChatKitConversationListViewController
│   │   └── ChatViewController.h/m              # Uses ChatKitConversationViewController directly
│   └── Network/
│       └── MockSSEURLProtocol.h/m   # Mock network for testing
├── project.yml                  # XcodeGen configuration
└── Makefile                     # Build automation
```

### Key Architecture Points

**Maximum Use of High-Level Objective-C APIs**:
- `ConversationListViewController` - Thin wrapper **embedding** `ChatKitConversationListViewController` as child
- **Zero custom coordinator wrapper** - uses `CKTChatKitCoordinator` directly
- **No connection screen** - coordinator initialized directly in SceneDelegate
- Framework handles all list management, search, swipe-to-delete automatically

**Note**: ChatKit view controllers are marked `final` in Swift, so Objective-C code must use composition (embedding as child view controller) rather than inheritance.

**What You DON'T Need in ObjC**:
- ❌ Custom `ChatCoordinator` wrapper around SDK coordinator
- ❌ Custom table view cells or data source implementations
- ❌ Custom search/filter logic
- ❌ Connection management UI
- ❌ Model classes (use `CKTConversationRecord` directly)

**Objective-C Best Practices**:
- Direct use of `CKTChatKitCoordinator` - no wrapping needed!
- Swift components accessible via `@import FinClipChatKit`
- ObjC-friendly initializers: `initWithObjCCoordinator:objcConfiguration:`
- Delegate pattern for callbacks

## 💡 Key Code Patterns

### Initialization

```objc
// In ConnectionViewController
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent;
self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

### Creating Conversation

```objc
[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        NSLog(@"Failed: %@", error);
        return;
    }
    
    // Show chat UI
    ChatKitConversationViewController *chatVC = 
        [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:self.coordinator
                                                    objcConfiguration:[CKTConversationConfiguration defaultConfiguration]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:chatVC animated:YES];
    });
}];
```

### Showing List UI

```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                               configuration:[CKTConversationListConfiguration defaultConfiguration]];
listVC.delegate = self;
[self addChildViewController:listVC];
[self.view addSubview:listVC.view];
[listVC didMoveToParentViewController:self];
```

## 📚 Learning Resources

### Documentation

- **[Quick Start Guide](../../docs/quick-start.md)** - Minimal skeleton code (includes ObjC)
- **[API Levels Guide](../../docs/api-levels.md)** - High-level vs low-level APIs
- **[Component Embedding Guide](../../docs/component-embedding.md)** - Embedding patterns
- **[Build Tooling Guide](../../docs/build-tooling.md)** - Makefile and XcodeGen
- **[Objective-C Guide](../../docs/objective-c-guide.md)** - Objective-C specific patterns

### Related Examples

- **[Simple](../Simple)** - Swift version using high-level APIs

## 🐛 Troubleshooting

### Build Errors

**"XcodeGen not found"**
- Install: `brew install xcodegen`

**"Module 'ChatKit' not found"**
- Run `make generate` to regenerate project
- Check `project.yml` has correct package dependency
- Verify Swift Package Manager resolved the dependency

**"'RuntimeCoordinator.h' file not found"**
- This is expected - old references have been removed
- Use `CKTChatKitCoordinator` instead

### Runtime Errors

**"Failed to create conversation"**
- Check server URL in `ConnectionViewController.m`
- Ensure backend server is running

**"Messages not persisting"**
- Verify `storageMode` is set to `CKTStorageModePersistent`
- Check CoreData container initialization

## 🤝 Contributing

Found an issue or want to add features? See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../../../LICENSE) for details

---

**Made with ❤️ by the FinClip team**
