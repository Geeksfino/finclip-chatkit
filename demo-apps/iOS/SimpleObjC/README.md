# SimpleObjC

Objective-C demo app for ChatKit framework.

This is the Objective-C version of the Simple demo app, demonstrating how to use ChatKit's high-level Objective-C APIs to build a conversational AI application.

## Features

- Complete Objective-C implementation
- Uses ChatKit's high-level ObjC APIs (`CKTChatKitCoordinator`, `CKTConversationManager`)
- Remote binary dependency from GitHub (version 0.6.1)
- Full conversation management
- Conversation list with search
- Chat interface with context providers

## Requirements

- iOS 16.0+
- Xcode 15.0+
- XcodeGen (install with `brew install xcodegen`)

## Building

### Generate Xcode Project

```bash
make generate
```

### Build and Run

```bash
make run
```

This will:
1. Generate the Xcode project
2. Build the app
3. Install it on the simulator
4. Launch it

### Open in Xcode

```bash
make open
```

## Project Structure

```
App/
├── AppDelegate.h/m          # App delegate
├── SceneDelegate.h/m        # Scene delegate
├── Coordinators/            # Chat coordinator
├── Models/                  # Data models
├── ViewControllers/         # UI view controllers
└── Network/                 # Network utilities
```

## Dependencies

This app uses the ChatKit framework from GitHub as a remote binary dependency:

- **Package**: `https://github.com/Geeksfino/finclip-chatkit.git`
- **Version**: `0.6.1`

The framework is automatically resolved via Swift Package Manager when you build the project.

## Key APIs Used

- `CKTChatKitCoordinator` - Main coordinator for managing runtime and conversations
- `CKTConversationManager` - Manages conversation lifecycle and records
- `CKTConversationRecord` - Conversation metadata
- `ChatHostingController` - Chat UI container

## See Also

- [Simple](../Simple) - Swift version of this demo app
- [ChatKit Documentation](../../../docs)

