# AI-Bank-OC

**AI-Bank-OC** is an Objective-C demonstration project showing how to integrate and use the Finclip ChatKit framework in an Objective-C iOS application. This example mirrors the functionality of the Swift-based AI-Bank example but is implemented entirely in Objective-C to help developers who prefer or need to use Objective-C in their projects.

## Overview

This example demonstrates:

- ✅ **Objective-C Integration** - How to import and use ChatKit framework from Objective-C
- 💬 **Chat Interface** - Building a chat UI with ChatKit components
- 🤖 **Agent Management** - Loading and switching between different AI agents
- 📝 **Conversation Management** - Creating, loading, and managing conversation history
- 🎨 **Custom UI Components** - Implementing drawer navigation and chat views
- 🔄 **Runtime Coordination** - Managing ChatKit runtime lifecycle

## Project Structure

```
AI-Bank-OC/
├── App/
│   ├── App/
│   │   ├── AppDelegate.h/m          # Application delegate
│   │   ├── SceneDelegate.h/m        # Scene delegate for UI lifecycle
│   │   └── Info.plist               # App configuration
│   │
│   ├── ViewControllers/
│   │   ├── MainChatViewController.h/m              # Main container view
│   │   ├── ChatViewController.h/m                  # Chat interface with ChatKit
│   │   ├── DrawerContainerViewController.h/m      # Drawer/side menu container
│   │   ├── DrawerViewController.h/m               # Side menu content
│   │   └── ConversationListViewController.h/m     # Conversation history
│   │
│   ├── Models/
│   │   ├── AgentInfo.h/m            # Agent information model
│   │   ├── AgentCatalog.h/m         # Catalog of available agents
│   │   ├── AgentManager.h/m         # Agent lifecycle management
│   │   └── ConversationRecord.h/m   # Conversation metadata
│   │
│   ├── Coordinators/
│   │   ├── RuntimeCoordinator.h/m       # ChatKit runtime coordination
│   │   └── ConversationManager.h/m      # Conversation state management
│   │
│   └── Resources/
│       ├── Assets.xcassets/         # Images and assets
│       └── Fixtures/                # Mock data for testing
│
├── Package.swift                     # Swift Package Manager manifest
├── project.yml                       # XcodeGen project specification
├── Makefile                          # Build automation
└── README.md                         # This file
```

## Requirements

- **Xcode**: 15.0 or later
- **iOS**: 16.0 or later
- **Swift**: 5.9 or later (for ChatKit framework)
- **Tools**: XcodeGen (for project generation)

## Installation

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Generate Xcode Project

```bash
make project
```

Or manually:

```bash
xcodegen generate
```

### 3. Open and Build

```bash
open AI-Bank-OC.xcodeproj
```

Then build and run in Xcode (⌘R).

## Building and Running

### Using Make

```bash
# Generate project
make project

# Build
make build

# Run on simulator
make run

# Clean
make clean
```

### Using Xcode

1. Generate the project: `make project`
2. Open `AI-Bank-OC.xcodeproj`
3. Select a simulator or device
4. Press ⌘R to build and run

## Key Implementation Details

### Importing ChatKit in Objective-C

```objective-c
@import ChatKit;
```

ChatKit is a Swift framework, but it's accessible from Objective-C through module imports. The framework exposes its public API with appropriate `@objc` annotations.

### Runtime Coordination

The `RuntimeCoordinator` class demonstrates how to:

1. **Initialize ChatKit runtime**:
```objective-c
- (void)setupChatKitRuntime {
    // Initialize ChatKit runtime
    // self.chatKitRuntime = [[ChatKitRuntime alloc] initWithConfiguration:config];
}
```

2. **Load an agent**:
```objective-c
- (void)loadAgentWithInfo:(AgentInfo *)agentInfo {
    self.currentAgentInfo = agentInfo;
    // Configure ChatKit with agent
}
```

3. **Send messages**:
```objective-c
- (void)sendMessage:(NSString *)message 
         completion:(void (^)(NSString *response, NSError *error))completion {
    // Send through ChatKit runtime
    [self.chatKitRuntime sendMessage:message completion:^(ChatKitResponse *response, NSError *error) {
        // Handle response
        completion(response.text, error);
    }];
}
```

### Agent Catalog

The `AgentCatalog` provides a collection of pre-configured agents:

- **Banking Assistant** - Account inquiries and transactions
- **Investment Advisor** - Portfolio analysis and recommendations
- **Loan Calculator** - Loan calculations and eligibility

### Conversation Management

The `ConversationManager` handles:

- Creating new conversations
- Loading existing conversations
- Adding messages to conversation history
- Deleting conversations

## Comparing with Swift Version

This Objective-C implementation mirrors the Swift AI-Bank example with these adaptations:

| Aspect | Swift | Objective-C |
|--------|-------|-------------|
| **Properties** | `var` / `let` | `@property` |
| **Nullability** | Optional `?` | Nullable annotations |
| **Initialization** | `init()` | `- (instancetype)init` |
| **Closures** | `{ }` | Blocks `^{ }` |
| **Import** | `import ChatKit` | `@import ChatKit` |
| **String Interpolation** | `"\(value)"` | `[NSString stringWithFormat:]` |

## Features Demonstrated

### 1. Chat Interface
- Text input and display
- Message history
- Keyboard handling
- Auto-scrolling

### 2. Drawer Navigation
- Side menu with smooth animations
- Overlay for dismissal
- Navigation options

### 3. Agent Management
- Multiple agent support
- Agent switching
- Configuration per agent

### 4. Conversation History
- List of past conversations
- Conversation metadata
- Load/delete functionality

## Extending the Example

### Adding a New Agent

1. Edit `AgentCatalog.m`:

```objective-c
AgentInfo *newAgent = [[AgentInfo alloc] init];
newAgent.agentId = @"my-agent";
newAgent.name = @"My Agent";
newAgent.agentDescription = @"Description";
newAgent.serverURL = @"https://api.example.com/agent";
[agentArray addObject:newAgent];
```

### Customizing the UI

The UI is built programmatically, making it easy to customize:

- Modify `ChatViewController.m` for chat interface changes
- Edit `DrawerViewController.m` for menu customization
- Adjust `MainChatViewController.m` for layout changes

### Adding Persistence

To persist conversations:

1. Implement Core Data or file-based storage in `ConversationManager`
2. Save messages and metadata
3. Load on app launch

## Troubleshooting

### Build Errors

**Error**: "Module 'ChatKit' not found"
- **Solution**: Ensure Swift Package Manager has resolved dependencies. Clean and rebuild.

**Error**: "Command PhaseScriptExecution failed"
- **Solution**: Run `make clean` and regenerate project with `make project`

### Runtime Issues

**Issue**: Agent not responding
- **Check**: Verify server URL configuration in `AgentCatalog.m`
- **Check**: Ensure network permissions in Info.plist

**Issue**: UI not updating
- **Check**: Ensure callbacks are dispatched to main queue

## Testing

The example includes mock responses for testing without a backend:

- `RuntimeCoordinator` includes simulated agent responses
- Modify `sendMessage:completion:` to add more test scenarios

## Learn More

- **ChatKit Documentation**: `/Users/cliang/repos/finclip/finclip-chatkit/docs/`
- **Swift Example**: `../AI-Bank/` - Swift version of this example
- **Integration Guide**: See `docs/integration-guide.md`

## Contributing

Improvements and bug fixes are welcome! Please:

1. Follow Objective-C coding conventions
2. Maintain parity with Swift example where possible
3. Add comments for complex logic
4. Test on multiple iOS versions

## License

This example is part of the Finclip ChatKit distribution and follows the same license.

## Support

For questions or issues:

- Check the main ChatKit documentation
- Review the Swift AI-Bank example
- Open an issue in the repository

---

**Note**: This is a demonstration project. For production use, implement proper error handling, security measures, and user authentication.


