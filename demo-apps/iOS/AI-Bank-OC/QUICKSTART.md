# AI-Bank-OC Quick Start Guide

Get up and running with the AI-Bank-OC Objective-C example in 5 minutes.

## Prerequisites

- macOS with Xcode 15.0+
- Command Line Tools installed
- Homebrew (for installing dependencies)

## Installation Steps

### 1. Install XcodeGen

```bash
brew install xcodegen
```

### 2. Navigate to Project Directory

```bash
cd /Users/cliang/repos/finclip/finclip-chatkit/demo-apps/iOS/AI-Bank-OC
```

### 3. Generate Xcode Project

```bash
make project
```

This will:
- Parse `project.yml`
- Resolve Swift Package dependencies
- Generate `AI-Bank-OC.xcodeproj`

### 4. Open in Xcode

```bash
open AI-Bank-OC.xcodeproj
```

Or use:
```bash
xed .
```

### 5. Build and Run

In Xcode:
1. Select a simulator (iPhone 15 recommended)
2. Press ⌘R to build and run

Or from terminal:
```bash
make run
```

## What You'll See

The app demonstrates:

1. **Main Chat Screen**
   - Clean chat interface
   - Message input field
   - Send button
   - Menu button (top left)

2. **Side Drawer Menu**
   - Tap menu button to open
   - Access conversations
   - View settings
   - About information

3. **Agent Interaction**
   - Banking Assistant (default)
   - Investment Advisor
   - Loan Calculator

## Try These Actions

### Send a Message

1. Type in the input field: "What's my account balance?"
2. Tap Send
3. View the simulated response

### Open the Menu

1. Tap the ☰ button (top left)
2. Browse menu options
3. Tap outside to close

### View Conversations

1. Open menu
2. Tap "Conversations"
3. See list of past conversations (empty initially)

## Project Structure Overview

```
AI-Bank-OC/
├── App/
│   ├── App/                    # App lifecycle (AppDelegate, SceneDelegate)
│   ├── ViewControllers/        # UI controllers
│   ├── Models/                 # Data models
│   ├── Coordinators/           # Business logic coordinators
│   └── Resources/              # Assets and fixtures
│
├── Package.swift               # Dependencies
├── project.yml                 # Project configuration
├── Makefile                    # Build commands
└── README.md                   # Full documentation
```

## Key Files to Explore

### Core Integration

**`RuntimeCoordinator.m`** - Shows how to:
- Import ChatKit in Objective-C
- Initialize the runtime
- Send messages
- Handle responses

```objective-c
@import ChatKit;

- (void)sendMessage:(NSString *)message 
         completion:(void (^)(NSString *, NSError *))completion {
    [self.runtime sendMessage:message completion:^(ChatKitResponse *response, NSError *error) {
        // Handle response
    }];
}
```

### UI Implementation

**`ChatViewController.m`** - Demonstrates:
- Building UI programmatically
- Auto Layout constraints
- Keyboard handling
- Message display

### Model Layer

**`AgentCatalog.m`** - Shows:
- Creating agent configurations
- Managing multiple agents
- Agent metadata

## Common Commands

```bash
# Generate/regenerate project
make project

# Build only
make build

# Run on simulator
make run

# Clean everything
make clean

# View all commands
make help
```

## Customization Ideas

### 1. Add a New Agent

Edit `AgentCatalog.m`:

```objective-c
AgentInfo *customAgent = [[AgentInfo alloc] init];
customAgent.agentId = @"custom-agent";
customAgent.name = @"Custom Agent";
customAgent.agentDescription = @"Your custom agent description";
customAgent.serverURL = @"https://your-api.com";
[agentArray addObject:customAgent];
```

### 2. Customize UI Colors

Edit `ChatViewController.m`:

```objective-c
self.view.backgroundColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.97 alpha:1.0];
self.messagesTextView.backgroundColor = [UIColor whiteColor];
```

### 3. Add Menu Items

Edit `DrawerViewController.m`:

```objective-c
self.menuItems = @[@"Conversations", @"Settings", @"About", @"New Item"];
```

## Troubleshooting

### "Module 'ChatKit' not found"

```bash
# Solution 1: Clean and rebuild
make clean
make project

# Solution 2: Reset packages in Xcode
# File → Packages → Reset Package Caches
```

### "xcodegen: command not found"

```bash
# Install XcodeGen
brew install xcodegen
```

### Build fails with signing issues

1. Open project in Xcode
2. Select target "AI-Bank-OC"
3. Go to "Signing & Capabilities"
4. Set Team to your Apple Developer account
5. Or use "Automatically manage signing"

### Simulator not running

```bash
# List available simulators
xcrun simctl list devices

# Boot a simulator manually
xcrun simctl boot "iPhone 15"

# Then run
make run
```

## Next Steps

### Learn More

- 📖 Read [README.md](README.md) for full documentation
- 🔧 See [OBJC_CHATKIT_GUIDE.md](OBJC_CHATKIT_GUIDE.md) for Objective-C specifics
- 📝 Compare with Swift version in `../AI-Bank/`

### Extend the Example

- [ ] Add persistent storage with Core Data
- [ ] Implement real network calls
- [ ] Add user authentication
- [ ] Create custom UI themes
- [ ] Add voice input
- [ ] Implement markdown message rendering

### Connect to Real Backend

1. Update `AgentCatalog.m` with real server URLs
2. Implement actual API calls in `RuntimeCoordinator.m`
3. Add authentication tokens
4. Handle real-time updates

## Resources

- **ChatKit Docs**: `/Users/cliang/repos/finclip/finclip-chatkit/docs/`
- **Swift Example**: `../AI-Bank/`
- **Apple Docs**: [developer.apple.com](https://developer.apple.com)

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the full [README.md](README.md)
3. Look at the [OBJC_CHATKIT_GUIDE.md](OBJC_CHATKIT_GUIDE.md)
4. Compare with the Swift AI-Bank example
5. Open an issue in the repository

---

**Happy Coding!** 🚀

The AI-Bank-OC example demonstrates production-ready patterns for integrating ChatKit in Objective-C projects. Use it as a foundation for your own applications.


