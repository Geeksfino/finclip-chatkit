# Configuration Guide

This guide covers all configuration options available in FinClip ChatKit for customizing chat UI behavior, appearance, and functionality.

---

## Table of Contents

1. [ChatKitConversationConfiguration](#chatkitconversationconfiguration)
2. [ChatKitConversationListConfiguration](#chatkitconversationlistconfiguration)
3. [NeuronKitConfig Basics](#neuronkitconfig-basics)
4. [Theme Customization](#theme-customization)
5. [Prompt Starters Configuration](#prompt-starters-configuration)
6. [Context Providers Configuration](#context-providers-configuration)
7. [Performance Configuration](#performance-configuration)
8. [Debug Configuration](#debug-configuration)

---

## ChatKitConversationConfiguration

`ChatKitConversationConfiguration` provides customization points for `ChatKitConversationViewController` without requiring subclassing or delegate implementation.

### Basic Configuration

```swift
import FinClipChatKit

var config = ChatKitConversationConfiguration.default

// Basic settings
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "Hello! How can I help you today?" }

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Status Banner Configuration

Control the connection status banner appearance and behavior:

```swift
var config = ChatKitConversationConfiguration.default

// Show/hide banner
config.showStatusBanner = true

// Auto-hide settings
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0  // Hide after 2 seconds

// Customize style
var bannerStyle = StatusBannerStyle.default
bannerStyle.height = 30.0
bannerStyle.font = .systemFont(ofSize: 12, weight: .medium)
bannerStyle.textColor = .white
bannerStyle.defaultColors = [
    "Connected": .systemGreen,
    "Connecting...": .systemOrange,
    "Reconnecting...": .systemOrange,
    "Disconnected": .systemRed
]
config.statusBannerStyle = bannerStyle

// Custom color provider
config.statusBannerColorProvider = { status in
    switch status {
    case "Connected": return .systemGreen
    case "Disconnected": return .systemRed
    default: return .systemOrange
    }
}
```

### Welcome Message Configuration

```swift
var config = ChatKitConversationConfiguration.default

// Enable welcome message
config.showWelcomeMessage = true

// Static message
config.welcomeMessageProvider = { "Welcome! Start a conversation." }

// Dynamic message based on context
config.welcomeMessageProvider = {
    if isFirstTimeUser {
        return "Welcome! I'm here to help you get started."
    } else {
        return "Welcome back! How can I help you today?"
    }
}
```

### Composer Tools Configuration

Register tools that appear in the composer:

```swift
var config = ChatKitConversationConfiguration.default

config.toolsProvider = {
    [
        FinConvoComposerTool(
            toolId: "camera",
            title: "Camera",
            icon: UIImage(systemName: "camera.fill")
        ),
        FinConvoComposerTool(
            toolId: "photo",
            title: "Photo Library",
            icon: UIImage(systemName: "photo.fill")
        ),
        FinConvoComposerTool(
            toolId: "location",
            title: "Location",
            icon: UIImage(systemName: "location.fill")
        )
    ]
}
```

### Prompt Starters Configuration

Configure prompt starters that appear when starting new conversations:

```swift
var config = ChatKitConversationConfiguration.default

// Option 1: Use factory presets
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

// Option 2: Create custom starters
config.promptStartersProvider = {
    [
        FinConvoPromptStarter(
            starterId: "email",
            title: "Write a professional email",
            subtitle: nil,
            icon: UIImage(systemName: "envelope.fill"),
            payload: nil
        ),
        FinConvoPromptStarter(
            starterId: "brainstorm",
            title: "Help me brainstorm",
            subtitle: "Creative thinking",
            icon: UIImage(systemName: "lightbulb.fill"),
            payload: nil
        )
    ]
}

// Optional: Handle starter selection
config.onPromptStarterSelected = { starter in
    print("Selected: \(starter.title)")
    return false // false = auto-send message
}

// Optional: Customize style
let style = FinConvoPromptStarterStyle()
style.backgroundColor = .systemGray6
style.textColor = .label
config.promptStarterStyle = style

// Optional: Configure behavior mode (default: .autoHide)
// Use .manual to allow programmatic re-showing of starters
config.promptStarterBehaviorMode = .manual

// Optional: Insert to composer instead of auto-sending (default: false)
// When true, tapping a starter inserts text into composer for review
config.promptStarterInsertToComposerOnTap = true
```

> **📘 For detailed prompt starter configuration, see the [Prompt Starters Guide](./prompt-starters.md)**

### Context Providers Configuration

Configure context providers that enrich messages with additional information:

```swift
var config = ChatKitConversationConfiguration.default

config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            LocationContextProvider(),
            CalendarContextProvider(),
            DeviceStateProvider()
        ]
    }
}
```

> **📘 For detailed context provider configuration, see the [Context Providers Guide](./context-providers.md)**

### Complete Configuration Example

```swift
var config = ChatKitConversationConfiguration.default

// Status banner
config.showStatusBanner = true
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0

// Welcome message
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "Hello! How can I help?" }

// Prompt starters
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}
config.promptStarterBehaviorMode = .autoHide
config.promptStarterInsertToComposerOnTap = false

// Tools
config.toolsProvider = {
    [CameraTool(), PhotoLibraryTool()]
}

// Context providers
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [LocationContextProvider()]
    }
}

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Objective-C Configuration

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];

// Status banner
config.showStatusBanner = YES;
config.statusBannerAutoHide = YES;
config.statusBannerAutoHideDelay = 2.0;
config.statusBannerHeight = 30.0;
config.statusBannerTextColor = [UIColor whiteColor];
config.statusBannerConnectedColor = [UIColor systemGreenColor];

// Welcome message
config.showWelcomeMessage = YES;
config.welcomeMessage = @"Hello! How can I help?";

// Prompt starters
config.promptStartersEnabled = YES;
config.promptStarters = [ChatKitPromptStarterFactory createExampleStarters];
config.promptStarterBehaviorMode = FinConvoPromptStarterBehaviorModeAutoHide;
config.promptStarterInsertToComposerOnTap = NO;

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                       conversation:conversation
                                                    objcCoordinator:coordinator
                                                  objcConfiguration:config];
```

### Configuration Properties Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `showStatusBanner` | `Bool` | `true` | Whether to show connection status banner |
| `showWelcomeMessage` | `Bool` | `true` | Whether to show welcome message |
| `welcomeMessageProvider` | `() -> String?` | `nil` | Provider for welcome message text |
| `statusBannerStyle` | `StatusBannerStyle` | `.default` | Status banner style configuration |
| `statusBannerAutoHide` | `Bool` | `true` | Whether banner auto-hides after connection |
| `statusBannerAutoHideDelay` | `TimeInterval` | `2.0` | Auto-hide delay in seconds |
| `statusBannerColorProvider` | `(String) -> UIColor?` | `nil` | Custom color provider for status |
| `promptStartersProvider` | `() -> [FinConvoPromptStarter]?` | `nil` | Provider for prompt starters |
| `onPromptStarterSelected` | `(FinConvoPromptStarter) -> Bool?` | `nil` | Callback when starter is tapped |
| `promptStarterStyle` | `FinConvoPromptStarterStyle?` | `nil` | Style configuration for starters |
| `promptStarterBehaviorMode` | `FinConvoPromptStarterBehaviorMode` | `.autoHide` | Behavior mode (`.autoHide` or `.manual`) |
| `promptStarterInsertToComposerOnTap` | `Bool` | `false` | Insert to composer instead of auto-sending |
| `toolsProvider` | `() -> [FinConvoComposerTool]?` | `nil` | Provider for composer tools |
| `contextProvidersProvider` | `() -> [FinConvoComposerContextProvider]?` | `nil` | Provider for context providers |

---

## ChatKitConversationListConfiguration

`ChatKitConversationListConfiguration` provides customization points for `ChatKitConversationListViewController`.

### Basic Configuration

```swift
import FinClipChatKit

var config = ChatKitConversationListConfiguration.default

// Search configuration
config.searchPlaceholder = "Search conversations"
config.showSearchBar = true
config.searchEnabled = true

// Header configuration
config.showHeader = true
config.headerTitle = "Conversations"
config.headerIcon = UIImage(systemName: "message.fill")

// New conversation button
config.showNewButton = true

// Cell configuration
config.cellStyle = .default
config.rowHeight = 56.0
config.enableSwipeToDelete = true
config.enableLongPress = true

let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

### Cell Styles

```swift
var config = ChatKitConversationListConfiguration.default

// Default style (sidebar-style with title and preview)
config.cellStyle = .default

// Compact style (title only)
config.cellStyle = .compact

// Custom style (app provides cell via delegate)
config.cellStyle = .custom
```

### Objective-C Configuration

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];

config.searchPlaceholder = @"Search conversations";
config.showSearchBar = YES;
config.showHeader = YES;
config.headerTitle = @"Conversations";
config.showNewButton = YES;
config.rowHeight = 56.0;

ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithCoordinator:coordinator
                                                          configuration:config];
```

### Configuration Properties Reference

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `searchPlaceholder` | `String` | `"Search"` | Search bar placeholder text |
| `headerTitle` | `String?` | `nil` | Header title (nil hides header) |
| `headerIcon` | `UIImage?` | `nil` | Header icon image |
| `showHeader` | `Bool` | `true` | Whether to show header section |
| `showSearchBar` | `Bool` | `true` | Whether to show search bar |
| `showNewButton` | `Bool` | `true` | Whether to show new conversation button |
| `cellStyle` | `CellStyle` | `.default` | Cell style (`.default`, `.compact`, `.custom`) |
| `enableSwipeToDelete` | `Bool` | `true` | Whether swipe-to-delete is enabled |
| `enableLongPress` | `Bool` | `true` | Whether long-press actions are enabled |
| `searchEnabled` | `Bool` | `true` | Whether search functionality is enabled |
| `rowHeight` | `CGFloat` | `56.0` | Row height for conversation cells |

---

## NeuronKitConfig Basics

`NeuronKitConfig` is used to initialize `ChatKitCoordinator`, which manages the runtime lifecycle.

### Basic Configuration

```swift
import FinClipChatKit
import NeuronKit

let config = NeuronKitConfig(
    serverURL: URL(string: "wss://your-server.com")!,
    deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
    userId: "user-123",
    storage: .persistent
)

let coordinator = ChatKitCoordinator(config: config)
```

### Storage Configuration

Choose between persistent and in-memory storage:

```swift
// Persistent storage (recommended for production)
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .persistent  // Saves to CoreData
)

// In-memory storage (for testing only)
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .inMemory  // Lost on app restart
)
```

### Context Providers in NeuronKitConfig

Add context providers at runtime level:

```swift
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .persistent,
    contextProviders: [
        DeviceStateProvider(updatePolicy: .every(60)),       // Battery, storage
        NetworkStatusProvider(updatePolicy: .every(30)),     // Network type
        CalendarPeekProvider(updatePolicy: .onAppForeground) // Upcoming events
    ]
)
```

**Available Update Policies**:
- `.every(seconds)` - Update at regular intervals
- `.onAppForeground` - Update when app comes to foreground
- `.onDemand` - Update only when explicitly requested

> **📘 Note**: Context providers can also be configured via `ChatKitConversationConfiguration.contextProvidersProvider` for conversation-specific providers.

---

## Theme Customization

Customize the appearance of chat UI using `FinConvoTheme`.

### Basic Theme Setup

```swift
import ConvoUI

let chatView = FinConvoChatView()
let theme = FinConvoTheme.default()

// Customize and apply
chatView.theme = theme
```

### Color Customization

```swift
let theme = FinConvoTheme.default()

// Primary colors
theme.primaryColor = .systemBlue
theme.backgroundColor = .systemBackground

// Message bubbles
theme.userMessageBackgroundColor = .systemBlue
theme.userMessageTextColor = .white
theme.agentMessageBackgroundColor = .systemGray5
theme.agentMessageTextColor = .label

// Input area
theme.inputBackgroundColor = .secondarySystemBackground
theme.inputTextColor = .label
theme.sendButtonColor = .systemBlue

chatView.theme = theme
```

### Typography Customization

```swift
let theme = FinConvoTheme.default()

// Message text
theme.messageFont = .systemFont(ofSize: 16, weight: .regular)
theme.messageFontBold = .systemFont(ofSize: 16, weight: .bold)

// Timestamps
theme.timestampFont = .systemFont(ofSize: 12, weight: .light)

// Input
theme.inputFont = .systemFont(ofSize: 16)

chatView.theme = theme
```

### Spacing Customization

```swift
let theme = FinConvoTheme.default()

// Message spacing
theme.messageSpacing = 8.0
theme.messagePadding = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

// Bubble corner radius
theme.messageCornerRadius = 18.0

chatView.theme = theme
```

### Dark Mode Support

ChatKit themes automatically adapt to dark mode when using system colors:

```swift
let theme = FinConvoTheme.default()

// Use adaptive colors
theme.backgroundColor = .systemBackground           // Adapts automatically
theme.userMessageBackgroundColor = .systemBlue      // Works in both modes
theme.agentMessageBackgroundColor = .systemGray5    // Adapts automatically

chatView.theme = theme
```

---

## Prompt Starters Configuration

For comprehensive prompt starter configuration, see the [Prompt Starters Guide](./prompt-starters.md).

### Quick Reference

```swift
var config = ChatKitConversationConfiguration.default

// Enable prompt starters
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

// Behavior mode
config.promptStarterBehaviorMode = .manual  // or .autoHide

// Tap action
config.promptStarterInsertToComposerOnTap = true  // or false
```

---

## Context Providers Configuration

For comprehensive context provider configuration, see the [Context Providers Guide](./context-providers.md).

### Quick Reference

```swift
var config = ChatKitConversationConfiguration.default

config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            LocationContextProvider(),
            CalendarContextProvider(),
            DeviceStateProvider()
        ]
    }
}
```

---

## Performance Configuration

### Message Rendering Optimization

```swift
let chatView = FinConvoChatView()

// Limit visible messages for better performance
chatView.maxVisibleMessages = 100

// Enable lazy loading (if supported)
// chatView.enableLazyLoading = true
```

### Memory Management

```swift
class ChatViewController: ChatKitConversationViewController {
    deinit {
        // Clean up resources
        conversation?.unbindUI()
    }
}
```

---

## Debug Configuration

### Enable Debug Logging

```swift
// Enable verbose logging (DEBUG builds only)
#if DEBUG
// ChatKit logs are controlled by NeuronKit
// Check NeuronKit documentation for debug logging options
#endif
```

### Layout Validation

When using `ChatKitConversationViewController`, layout validation is handled automatically. For custom implementations:

```swift
let chatView = FinConvoChatView()

// Check for layout issues
chatView.setNeedsLayout()
chatView.layoutIfNeeded()
```

---

## Environment-Specific Configuration

### Development Configuration

```swift
#if DEBUG
let config = NeuronKitConfig(
    serverURL: URL(string: "wss://dev-server.com")!,
    deviceId: "dev-device",
    userId: "test-user",
    storage: .inMemory  // Don't persist in development
)
#endif
```

### Production Configuration

```swift
#if RELEASE
let config = NeuronKitConfig(
    serverURL: URL(string: "wss://prod-server.com")!,
    deviceId: UIDevice.current.identifierForVendor!.uuidString,
    userId: currentUser.id,
    storage: .persistent  // Persist in production
)
#endif
```

---

## Next Steps

- **[Developer Guide](./developer-guide.md)** - Advanced patterns and examples
- **[Objective-C Guide](./objective-c-guide.md)** - Objective-C specific configuration
- **[Prompt Starters Guide](./prompt-starters.md)** - Detailed prompt starter configuration
- **[Context Providers Guide](./context-providers.md)** - Detailed context provider configuration
- **[Troubleshooting](../troubleshooting.md)** - Common issues and solutions

---

**Last Updated**: November 2025  
**ChatKit Version**: 0.9.0+

