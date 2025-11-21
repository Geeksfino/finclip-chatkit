# Prompt Starters Guide

This guide explains how to implement and configure prompt starters in ChatKit. Prompt starters are predefined suggestion chips that appear at the top of new conversations, helping users quickly begin interacting with the AI assistant.

> **📘 Note:** Prompt starters are built on top of ConvoUI's prompt starter system. This guide covers both Swift and Objective-C implementations using ChatKit APIs.

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Using ChatKit APIs](#using-chatkit-apis)
4. [Custom Starters](#custom-starters)
5. [Styling](#styling)
6. [Advanced Usage](#advanced-usage)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What Are Prompt Starters?

Prompt starters are horizontal scrolling chips displayed at the top of the message list when:
- The chat view is newly initialized
- The conversation has 0 user messages
- They are configured via the SDK

**Key Behavior**: Starters always hide after user interaction (tap or send message) because they become irrelevant once the user has engaged. The difference between modes is in **re-showing capability** for context-aware scenarios.

### Key Benefits

- **Better UX** - Guide users toward meaningful interactions
- **Reduced Friction** - Help users get started quickly
- **Customizable** - Full control over content, styling, and behavior
- **Automatic Management** - Framework handles visibility and lifecycle

### Example Use Cases

- **General Chat** - "Help me with something", "Brainstorm ideas", "Explain something"
- **Email Assistant** - "Write a professional email", "Draft a meeting request"
- **Creative Tools** - "Generate a story", "Create a poem", "Design a logo concept"
- **Productivity** - "Plan my day", "Summarize this document", "Set reminders"

---

## Quick Start

### Swift: Using Factory Method

The easiest way to get started is using `ChatKitPromptStarterFactory`:

```swift
import FinClipChatKit
import ConvoUI

var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true

// Use factory for common starters
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Objective-C: Using Factory Method

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;

// Use factory for common starters
config.promptStartersProvider = ^NSArray * _Nonnull {
    return [ChatKitPromptStarterFactory createExampleStarters];
};

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];
```

---

## Using ChatKit APIs

### ChatKitPromptStarterFactory

ChatKit provides a factory class with pre-configured starter sets:

#### Available Factory Methods

**1. `createDefaultStarters()`** - Balanced set for general chat applications:

```swift
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createDefaultStarters()
}
```

Returns:
- "Help me with something" (questionmark.circle.fill icon)
- "Brainstorm ideas" (lightbulb.fill icon, "Creative thinking" subtitle)
- "Explain something" (book.fill icon, "Break it down simply" subtitle)

**2. `createExampleStarters()`** - Rich set similar to ChatGPT:

```swift
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}
```

Returns:
- "Write a professional email" (envelope.fill icon)
- "Help me brainstorm ideas" (lightbulb.fill icon, "Creative thinking and problem solving" subtitle)
- "Explain a complex topic" (book.fill icon, "Break it down simply" subtitle)
- "Plan my day efficiently" (calendar icon)

### ChatKitConversationConfiguration

Configure prompt starters via `ChatKitConversationConfiguration`:

```swift
var config = ChatKitConversationConfiguration.default

// Set prompt starters provider
config.promptStartersProvider = {
    // Return array of FinConvoPromptStarter
    return ChatKitPromptStarterFactory.createExampleStarters()
}

// Optional: Handle starter selection
config.onPromptStarterSelected = { starter in
    print("Selected starter: \(starter.starterId)")
    // Return false to auto-send, true to prevent auto-send
    return false
}

// Optional: Customize style
let style = FinConvoPromptStarterStyle()
style.backgroundColor = .systemBlue
style.textColor = .white
style.cornerRadius = 25.0
config.promptStarterStyle = style

// Optional: Configure behavior mode (default: .autoHide)
// Use .manual to allow programmatic re-showing of starters when context changes
config.promptStarterBehaviorMode = .manual

// Optional: Insert to composer instead of auto-sending (default: false)
// When true, tapping a starter inserts text into composer for review/edit
config.promptStarterInsertToComposerOnTap = true
```

### Behavior Modes

ChatKit supports two behavior modes for prompt starters:

**Auto-Hide Mode (Default):**
- Starters appear when chat is empty
- Hide after first user message or tap
- Once dismissed, cannot be shown again
- Traditional "one-time" behavior
- Best for: Simple chat apps, standard use cases

**Manual Mode:**
- Starters appear when chat is empty
- Hide after user interaction (same as auto-hide)
- **Can be programmatically re-shown** even when messages exist
- Perfect for context-aware apps
- Best for: Apps that change starters based on context/selection

### Tap Actions

Control what happens when a starter is tapped:

**Auto-Send (Default):**
- Starter title is automatically sent as a message
- Immediate action, no review step
- Set `promptStarterInsertToComposerOnTap = false` (default)

**Insert to Composer:**
- Starter title is inserted into the composer text field
- User can review, edit, and add context before sending
- Recommended for context-aware apps
- Set `promptStarterInsertToComposerOnTap = true`

---

## Custom Starters

### Creating Custom Starters (Swift)

```swift
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
            title: "Help me brainstorm ideas",
            subtitle: "Creative thinking",
            icon: UIImage(systemName: "lightbulb.fill"),
            payload: nil
        ),
        FinConvoPromptStarter(
            starterId: "explain",
            title: "Explain a complex topic",
            subtitle: "Break it down simply",
            icon: UIImage(systemName: "book.fill"),
            payload: ["category": "education"]
        )
    ]
}
```

### Creating Custom Starters (Objective-C)

```objc
config.promptStartersProvider = ^NSArray * _Nonnull {
    FinConvoPromptStarter *starter1 = [[FinConvoPromptStarter alloc] 
        initWithStarterId:@"email"
        title:@"Write a professional email"
        subtitle:nil
        icon:[UIImage systemImageNamed:@"envelope.fill"]
        payload:nil];
    
    FinConvoPromptStarter *starter2 = [[FinConvoPromptStarter alloc] 
        initWithStarterId:@"brainstorm"
        title:@"Help me brainstorm ideas"
        subtitle:@"Creative thinking"
        icon:[UIImage systemImageNamed:@"lightbulb.fill"]
        payload:nil];
    
    return @[starter1, starter2];
};
```

### FinConvoPromptStarter Properties

- **`starterId`** (String) - Unique identifier for the starter
- **`title`** (String) - Main text displayed on the chip (required)
- **`subtitle`** (String?) - Optional subtitle text
- **`icon`** (UIImage?) - Optional icon image
- **`payload`** (Any?) - Optional developer metadata

---

## Styling

### Using FinConvoPromptStarterStyle

Customize the appearance of prompt starter chips:

```swift
let style = FinConvoPromptStarterStyle()

// Colors
style.backgroundColor = .systemBlue
style.textColor = .white
style.subtitleTextColor = .systemGray

// Typography
style.titleFont = UIFont.boldSystemFont(ofSize: 16)
style.subtitleFont = UIFont.systemFont(ofSize: 13)

// Layout
style.cornerRadius = 25.0
style.horizontalSpacing = 12.0
style.verticalSpacing = 12.0
style.contentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
style.minimumHeight = 44.0

// Icon
style.iconSize = CGSize(width: 20, height: 20)

config.promptStarterStyle = style
```

### Objective-C Styling

```objc
FinConvoPromptStarterStyle *style = [[FinConvoPromptStarterStyle alloc] init];
style.backgroundColor = [UIColor systemBlueColor];
style.textColor = [UIColor whiteColor];
style.cornerRadius = 25.0;
style.titleFont = [UIFont boldSystemFontOfSize:16];

config.promptStarterStyle = style;
```

### Default Style

If no custom style is provided, the framework uses a default ChatGPT-like style:
- Background: `systemGray5`
- Text: `systemLabel`
- Corner radius: `20.0`
- Font: System font, 15pt medium for title, 13pt regular for subtitle

---

## Advanced Usage

### Context-Aware Starters (Manual Mode)

Use manual mode to show different starters based on context:

```swift
var config = ChatKitConversationConfiguration.default

// Enable manual mode for programmatic control
config.promptStarterBehaviorMode = .manual
config.promptStarterInsertToComposerOnTap = true

// Initial starters
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createDefaultStarters()
}

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)

// Later, when user selects a document context
func onDocumentSelected(_ document: Document) {
    // Update starters based on document type
    let newStarters = [
        FinConvoPromptStarter(
            starterId: "summarize",
            title: "Summarize this document",
            subtitle: nil,
            icon: UIImage(systemName: "doc.text"),
            payload: ["documentId": document.id]
        ),
        FinConvoPromptStarter(
            starterId: "analyze",
            title: "Analyze key points",
            subtitle: nil,
            icon: UIImage(systemName: "magnifyingglass"),
            payload: ["documentId": document.id]
        )
    ]
    
    // Update and show new starters (works in manual mode even with messages)
    chatVC.chatView.updatePromptStarters(newStarters)
    chatVC.chatView.showPromptStarters()
}
```

### Custom Selection Handling

Intercept starter selection to add custom logic:

```swift
config.onPromptStarterSelected = { starter in
    // Log analytics
    Analytics.track("prompt_starter_selected", properties: [
        "starter_id": starter.starterId,
        "title": starter.title
    ])
    
    // Custom handling for specific starters
    if starter.starterId == "special-starter" {
        // Do something special
        handleSpecialStarter(starter)
        return true // Prevent auto-send
    }
    
    // Default: auto-send the starter title as message
    return false
}
```

### Objective-C Selection Handling

```objc
config.onPromptStarterSelected = ^BOOL(FinConvoPromptStarter *starter) {
    NSLog(@"Selected starter: %@", starter.starterId);
    
    // Custom logic
    if ([starter.starterId isEqualToString:@"special-starter"]) {
        [self handleSpecialStarter:starter];
        return YES; // Prevent auto-send
    }
    
    return NO; // Allow auto-send
};
```

### Dynamic Starters

Update starters based on context:

```swift
class ChatViewController: ChatKitConversationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update starters based on user context
        updatePromptStarters()
    }
    
    private func updatePromptStarters() {
        let starters: [FinConvoPromptStarter]
        
        if userIsPremium {
            starters = createPremiumStarters()
        } else {
            starters = ChatKitPromptStarterFactory.createDefaultStarters()
        }
        
        chatView.setPromptStarters(starters)
    }
}
```

### Using Payload for Metadata

Store custom data with starters:

```swift
let starter = FinConvoPromptStarter(
    starterId: "email",
    title: "Write a professional email",
    subtitle: nil,
    icon: UIImage(systemName: "envelope.fill"),
    payload: [
        "category": "productivity",
        "difficulty": "easy",
        "estimatedTime": 2
    ]
)

// Access payload in selection handler
config.onPromptStarterSelected = { starter in
    if let payload = starter.payload as? [String: Any],
       let category = payload["category"] as? String {
        print("Category: \(category)")
    }
    return false
}
```

---

## Best Practices

### 1. Keep Titles Concise

**Good:**
- "Write a professional email"
- "Help me brainstorm ideas"
- "Explain a complex topic"

**Avoid:**
- "I would like you to help me write a professional email" (too long)
- "Email" (too vague)

### 2. Use Clear Action Verbs

Start with action verbs:
- ✅ "Write", "Explain", "Help", "Create", "Plan", "Summarize"
- ❌ "About", "Information", "Details"

### 3. Optimal Count

- **3-6 starters** is optimal
- Too few (1-2): Limited options
- Too many (7+): Overwhelming, harder to scroll

### 4. Make Them Specific

**Good:**
- "Write a professional email"
- "Plan my day efficiently"
- "Explain quantum physics simply"

**Avoid:**
- "Email" (too generic)
- "Help" (not specific enough)

### 5. Use Subtitles Strategically

Subtitles work well for:
- Clarifying the starter's purpose
- Adding context or examples
- Explaining the expected outcome

```swift
FinConvoPromptStarter(
    starterId: "brainstorm",
    title: "Help me brainstorm ideas",
    subtitle: "Creative thinking and problem solving", // Adds clarity
    icon: UIImage(systemName: "lightbulb.fill"),
    payload: nil
)
```

### 6. Choose Appropriate Icons

Use SF Symbols that match the starter's purpose:
- 📧 `envelope.fill` for email
- 💡 `lightbulb.fill` for brainstorming
- 📖 `book.fill` for explanations
- 📅 `calendar` for planning
- ✍️ `pencil` for writing

### 7. Test on Different Screen Sizes

Ensure horizontal scrolling works well on:
- iPhone SE (small screens)
- iPhone Pro Max (large screens)
- iPad (very wide screens)

### 8. Consider Localization

Provide localized titles for international users:

```swift
config.promptStartersProvider = {
    [
        FinConvoPromptStarter(
            starterId: "email",
            title: NSLocalizedString("prompt_starter.email", comment: "Write a professional email"),
            subtitle: nil,
            icon: UIImage(systemName: "envelope.fill"),
            payload: nil
        )
    ]
}
```

---

## Troubleshooting

### Starters Not Showing

**Problem:** Prompt starters don't appear in the chat view.

**Solutions:**
- ✅ Verify `promptStartersProvider` is set in configuration
- ✅ Check that conversation has 0 user messages (starters only show for new conversations)
- ✅ Ensure starters array is not empty
- ✅ Verify configuration is passed to `ChatKitConversationViewController` initializer

### Starters Not Hiding

**Problem:** Starters remain visible after sending a message.

**Solutions:**
- ✅ This should happen automatically - check framework logs
- ✅ Verify message was actually sent (check conversation state)
- ✅ Ensure you're not manually showing starters after message send
- ✅ In auto-hide mode, starters should hide and cannot be re-shown
- ✅ In manual mode, you can programmatically re-show, but they still hide after user interaction

### Custom Callback Not Called

**Problem:** `onPromptStarterSelected` callback is not invoked.

**Solutions:**
- ✅ Verify callback is set on configuration before view controller initialization
- ✅ Check callback signature matches expected type: `(FinConvoPromptStarter) -> Bool`
- ✅ Ensure callback is not `nil`

### Style Not Applied

**Problem:** Custom style settings are not reflected in UI.

**Solutions:**
- ✅ Verify `promptStarterStyle` is set before view controller initialization
- ✅ Check that style properties are set correctly
- ✅ Ensure style object is not `nil`

### Objective-C: Factory Method Not Found

**Problem:** `ChatKitPromptStarterFactory` methods not accessible in Objective-C.

**Solutions:**
- ✅ Ensure you're importing: `#import <FinClipChatKit/FinClipChatKit-Swift.h>`
- ✅ Use the `@objc` exposed methods: `createDefaultStarters()` and `createExampleStarters()`
- ✅ Check that you're using the correct factory class name

---

## Examples

### Complete Swift Example

**Example 1: Traditional Auto-Hide Mode (Default)**

```swift
import UIKit
import FinClipChatKit
import ConvoUI

final class ChatViewController: ChatKitConversationViewController {
    init(record: ConversationRecord, conversation: Conversation, coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationConfiguration.default
        config.showStatusBanner = true
        config.showWelcomeMessage = true
        config.welcomeMessageProvider = { "Hello! How can I help you today?" }
        
        // Configure prompt starters (default: auto-hide mode, auto-send)
        config.promptStartersProvider = {
            ChatKitPromptStarterFactory.createExampleStarters()
        }
        
        // Handle starter selection
        config.onPromptStarterSelected = { starter in
            print("User selected: \(starter.title)")
            // Return false to auto-send, true to prevent
            return false
        }
        
        // Customize style
        let style = FinConvoPromptStarterStyle()
        style.backgroundColor = .systemBlue
        style.textColor = .white
        style.cornerRadius = 25.0
        config.promptStarterStyle = style
        
        super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

**Example 2: Context-Aware Manual Mode**

```swift
final class DocumentChatViewController: ChatKitConversationViewController {
    init(record: ConversationRecord, conversation: Conversation, coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationConfiguration.default
        
        // Enable manual mode for context-aware starters
        config.promptStarterBehaviorMode = .manual
        config.promptStarterInsertToComposerOnTap = true
        
        // Initial starters
        config.promptStartersProvider = {
            ChatKitPromptStarterFactory.createDefaultStarters()
        }
        
        super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
    }
    
    func updateStartersForDocument(_ document: Document) {
        let documentStarters = [
            FinConvoPromptStarter(
                starterId: "summarize",
                title: "Summarize this document",
                subtitle: nil,
                icon: UIImage(systemName: "doc.text"),
                payload: ["documentId": document.id]
            )
        ]
        
        // Update and show new starters (works in manual mode)
        chatView.updatePromptStarters(documentStarters)
        chatView.showPromptStarters()
    }
}
```

### Complete Objective-C Example

**Example 1: Traditional Auto-Hide Mode (Default)**

```objc
#import <UIKit/UIKit.h>
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface ChatViewController : ChatKitConversationViewController
@end

@implementation ChatViewController

- (instancetype)initWithRecord:(CKTConversationRecord *)record 
                  conversation:(id)conversation 
                   coordinator:(CKTChatKitCoordinator *)coordinator {
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    config.showStatusBanner = YES;
    config.showWelcomeMessage = YES;
    config.welcomeMessageProvider = ^NSString * _Nullable {
        return @"Hello! How can I help you today?";
    };
    
    // Configure prompt starters (default: auto-hide mode, auto-send)
    config.promptStartersProvider = ^NSArray * _Nonnull {
        return [ChatKitPromptStarterFactory createExampleStarters];
    };
    
    // Handle starter selection
    config.onPromptStarterSelected = ^BOOL(FinConvoPromptStarter *starter) {
        NSLog(@"User selected: %@", starter.title);
        return NO; // Allow auto-send
    };
    
    // Customize style
    FinConvoPromptStarterStyle *style = [[FinConvoPromptStarterStyle alloc] init];
    style.backgroundColor = [UIColor systemBlueColor];
    style.textColor = [UIColor whiteColor];
    style.cornerRadius = 25.0;
    config.promptStarterStyle = style;
    
    self = [super initWithObjCRecord:record
                         conversation:conversation
                      objcCoordinator:coordinator
                    objcConfiguration:config];
    return self;
}

@end
```

**Example 2: Context-Aware Manual Mode**

```objc
@interface DocumentChatViewController : ChatKitConversationViewController
@end

@implementation DocumentChatViewController

- (instancetype)initWithRecord:(CKTConversationRecord *)record 
                  conversation:(id)conversation 
                   coordinator:(CKTChatKitCoordinator *)coordinator {
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    
    // Enable manual mode for context-aware starters
    config.promptStarterBehaviorMode = FinConvoPromptStarterBehaviorModeManual;
    config.promptStarterInsertToComposerOnTap = YES;
    
    // Initial starters
    config.promptStartersProvider = ^NSArray * _Nonnull {
        return [ChatKitPromptStarterFactory createDefaultStarters];
    };
    
    self = [super initWithObjCRecord:record
                         conversation:conversation
                      objcCoordinator:coordinator
                    objcConfiguration:config];
    return self;
}

- (void)updateStartersForDocument:(Document *)document {
    FinConvoPromptStarter *starter = [[FinConvoPromptStarter alloc]
        initWithStarterId:@"summarize"
        title:@"Summarize this document"
        subtitle:nil
        icon:[UIImage systemImageNamed:@"doc.text"]
        payload:@{@"documentId": document.id}];
    
    // Update and show new starters (works in manual mode)
    [self.chatView updatePromptStarters:@[starter]];
    [self.chatView showPromptStarters];
}

@end
```

---

## Related Documentation

- **[Developer Guide](./developer-guide.md)** - Complete ChatKit development guide
- **[Objective-C Guide](./objective-c-guide.md)** - Objective-C specific patterns
- **[Context Providers Guide](./context-providers.md)** - Adding context to messages
- **[Component Embedding](../component-embedding.md)** - Embedding chat components

---

## Demo Apps

Working examples are available in the demo apps:

- **Simple (Swift):** See `demo-apps/iOS/Simple/App/ViewControllers/ChatViewController.swift`
- **MyChatGPT:** See `chatkit/Examples/MyChatGPT/` for a complete prompt starters implementation

---

---

## Configuration Reference

### ChatKitConversationConfiguration Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `promptStartersProvider` | `() -> [FinConvoPromptStarter]?` | `nil` | Provider function that returns array of starters |
| `onPromptStarterSelected` | `(FinConvoPromptStarter) -> Bool?` | `nil` | Callback when starter is tapped. Return `true` to prevent auto-send |
| `promptStarterStyle` | `FinConvoPromptStarterStyle?` | `nil` | Custom styling configuration |
| `promptStarterBehaviorMode` | `FinConvoPromptStarterBehaviorMode` | `.autoHide` | Behavior mode: `.autoHide` or `.manual` |
| `promptStarterInsertToComposerOnTap` | `Bool` | `false` | When `true`, inserts text into composer instead of auto-sending |

### CKTConversationConfiguration Properties (Objective-C)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `promptStartersEnabled` | `BOOL` | `NO` | Whether prompt starters are enabled |
| `promptStarters` | `NSArray<FinConvoPromptStarter *>?` | `nil` | Array of prompt starters |
| `promptStarterBehaviorMode` | `FinConvoPromptStarterBehaviorMode` | `FinConvoPromptStarterBehaviorModeAutoHide` | Behavior mode |
| `promptStarterInsertToComposerOnTap` | `BOOL` | `NO` | Insert to composer instead of auto-sending |

---

**Last Updated**: November 2025  
**ChatKit Version**: 0.9.0+

