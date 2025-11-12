# API Levels Guide

ChatKit provides multiple API levels to suit different use cases. This guide explains when to use each level and how they differ.

---

## Overview

ChatKit offers three ways to integrate:

1. **High-Level APIs** (Recommended) - Simple, ready-made components
2. **Low-Level APIs** (Advanced) - Maximum flexibility, more boilerplate
3. **Provider Mechanism** - Customize framework behavior without changing code

---

## High-Level APIs (Recommended)

**Best for**: Most applications, rapid development, standard chat UI

The high-level APIs provide ready-made components that handle most common use cases with minimal code.

### Key Components

#### ChatKitCoordinator
Manages runtime lifecycle safely. Create once at app launch.

```swift
let config = NeuronKitConfig.default(serverURL: serverURL)
    .withUserId("user-123")
let coordinator = ChatKitCoordinator(config: config)
```

#### ChatKitConversationManager
Tracks multiple conversations automatically. Optional but recommended for multi-session apps.

```swift
let manager = ChatKitConversationManager()
manager.attach(runtime: coordinator.runtime)
```

#### ChatKitConversationViewController
Ready-made chat UI with message rendering, input composer, and all interactions.

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)
```

#### ChatKitConversationListViewController
Ready-made conversation list with search, swipe actions, and selection handling.

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)
```

### Example: Simple App Pattern

The **Simple** demo app demonstrates high-level APIs:

```swift
// 1. Initialize once at app launch
let coordinator = ChatKitCoordinator(config: config)

// 2. Create conversation when user requests it
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)

// 3. Show ready-made chat UI
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

**Benefits**:
- ✅ Minimal code (20-30 lines for basic chat)
- ✅ Handles all UI interactions automatically
- ✅ Consistent behavior and styling
- ✅ Built-in features (search, swipe actions, etc.)
- ✅ Safe lifecycle management

**See**: 
- `demo-apps/iOS/Simple/` - Swift example
- `demo-apps/iOS/SimpleObjC/` - Objective-C example

---

## Low-Level APIs (Advanced)

**Best for**: Custom UI requirements, maximum control, non-standard layouts

The low-level APIs give you direct access to the underlying components, allowing complete customization at the cost of more boilerplate code.

### Key Components

#### Direct NeuronRuntime Access
Access the runtime directly for custom orchestration.

```swift
let runtime = coordinator.runtime
// Direct runtime manipulation
```

#### ChatHostingController + ChatKitAdapter
Manual UI binding for custom chat implementations.

```swift
let hosting = ChatHostingController()
let adapter = ChatKitAdapter(chatView: hosting.chatView)
conversation.bindUI(adapter)
```

#### Custom UI Implementation
Build your own UI using framework primitives.

### When to Use Low-Level APIs

Use low-level APIs when you need:
- Custom message rendering
- Non-standard UI layouts
- Specialized interaction patterns
- Integration with existing custom UI frameworks

### Trade-offs

**Advantages**:
- ✅ Complete control over UI and behavior
- ✅ Can integrate with any UI framework
- ✅ Maximum flexibility

**Disadvantages**:
- ❌ Significantly more code (200+ lines vs 20-30)
- ❌ Must handle lifecycle manually
- ❌ More boilerplate (binding, unbinding, state management)
- ❌ Must implement features yourself (search, actions, etc.)
- ❌ Higher maintenance burden

### Example Pattern

A low-level implementation typically involves:

1. Creating and managing `ChatHostingController`
2. Manually binding/unbinding `ChatKitAdapter`
3. Implementing custom UI components
4. Handling all lifecycle events
5. Managing conversation state manually

**Note**: The framework provides low-level APIs for maximum flexibility, but most developers should use high-level APIs. Low-level APIs are verbose and require significant boilerplate code.

---

## Provider Mechanism

**Best for**: Customizing framework behavior without modifying framework code

Providers allow you to inject custom logic into the framework at specific points.

### Context Providers

Attach contextual information (location, calendar events, etc.) to messages via the composer UI.

#### Swift Implementation

```swift
import FinClipChatKit
import ConvoUI

class LocationContextProvider: ConvoUIContextProvider {
    func provideContext(completion: @escaping (ConvoUIContext?) -> Void) {
        // Your location logic
        let context = ConvoUIContext(
            title: "Current Location",
            content: "Lat: 37.7749, Lng: -122.4194"
        )
        completion(context)
    }
}

// Register in ChatKitConversationConfiguration
var config = ChatKitConversationConfiguration.default
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            ConvoUIContextProviderBridge(provider: LocationContextProvider()),
            ConvoUIContextProviderBridge(provider: CalendarContextProvider())
        ]
    }
}
```

#### Objective-C Implementation

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyLocationProvider : NSObject <FinConvoComposerContextProvider>
@end

@implementation MyLocationProvider

- (void)provideContextWithCompletion:(void (^)(FinConvoContext * _Nullable))completion {
    // Your location logic
    FinConvoContext *context = [[FinConvoContext alloc] initWithTitle:@"Location"
                                                               content:@"Lat: 37.7749, Lng: -122.4194"];
    completion(context);
}

@end

// Register via ChatKitConversationConfiguration
```

### ASR Providers

Provide custom Automatic Speech Recognition for press-and-talk voice input.

#### Objective-C Implementation

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Your ASR implementation (e.g., OpenAI Whisper, Google Speech-to-Text)
    // Process audio and return transcribed text
    completion(transcribedText, nil);
}

- (void)cancelTranscription {
    // Cancel any ongoing requests
}

@end

// Register via ChatKitConversationConfiguration
```

**Default**: If no ASR provider is specified, ChatKit uses Apple's Speech framework.

### Title Generation Providers

Customize how conversation titles are generated.

#### Swift Implementation

```swift
class CustomTitleProvider: ConversationTitleProvider {
    func shouldGenerateTitle(
        sessionId: UUID,
        messageCount: Int,
        currentTitle: String?
    ) async -> Bool {
        // Return true when title should be generated
        return messageCount >= 3 && currentTitle == nil
    }
    
    func generateTitle(messages: [NeuronMessage]) async throws -> String? {
        // Your title generation logic (e.g., LLM call)
        // Use first few messages to generate title
        return try await callLLMForTitle(messages: messages)
    }
}

// Register when creating ChatKitConversationManager
let manager = ChatKitConversationManager(titleProvider: CustomTitleProvider())
```

#### Objective-C Implementation

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface MyTitleProvider : NSObject <CKTConversationTitleProvider>
@end

@implementation MyTitleProvider

- (void)shouldGenerateTitleForSessionId:(NSString *)sessionId
                           messageCount:(NSInteger)messageCount
                           currentTitle:(NSString *)currentTitle
                             completion:(void (^)(BOOL))completion {
    // Return YES when title should be generated
    completion(messageCount >= 3 && currentTitle == nil);
}

- (void)generateTitleForSessionId:(NSString *)sessionId
                         messages:(NSArray *)messages
                       completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Your title generation logic
    // messages is an array of dictionaries with message data
    [self callLLMForTitle:messages completion:^(NSString *title, NSError *error) {
        completion(title, error);
    }];
}

@end

// Register when creating CKTConversationManager
CKTConversationManager *manager = [[CKTConversationManager alloc] initWithTitleProvider:[[MyTitleProvider alloc] init]];
```

**Default**: If no title provider is specified, ChatKit extracts a title from the first user message.

---

## Choosing the Right API Level

### Use High-Level APIs If:
- ✅ You want standard chat UI
- ✅ You want rapid development
- ✅ You're building a typical chat app
- ✅ You want minimal code

**Start here**: Most developers should use high-level APIs.

### Use Low-Level APIs If:
- ⚠️ You need completely custom UI
- ⚠️ You're integrating with existing custom frameworks
- ⚠️ You have specialized interaction requirements
- ⚠️ You're willing to write significantly more code

**Warning**: Low-level APIs require 10x more code and manual lifecycle management.

### Use Providers If:
- ✅ You want to customize specific behaviors
- ✅ You need custom context, ASR, or title generation
- ✅ You want to extend framework without modifying it

**Note**: Providers work with both high-level and low-level APIs.

---

## Migration Path

### From Low-Level to High-Level

If you're currently using low-level APIs, migrating to high-level APIs is straightforward:

1. Replace `ChatHostingController` + `ChatKitAdapter` with `ChatKitConversationViewController`
2. Use `ChatKitCoordinator.startConversation()` instead of manual conversation creation
3. Use `ChatKitConversationListViewController` instead of custom list UI
4. Remove manual binding/unbinding code

**Result**: 90% less code, same functionality.

---

## Examples

### High-Level API Example
See: `demo-apps/iOS/Simple/` (Swift) and `demo-apps/iOS/SimpleObjC/` (Objective-C)

### Low-Level API Pattern
See: `demo-apps/iOS/MyChatGPT/` (conceptual reference - demonstrates pattern, not recommended for most developers)

---

## Next Steps

- **[Quick Start Guide](./quick-start.md)** - Get started with high-level APIs (Swift & Objective-C)
- **[Component Embedding Guide](./component-embedding.md)** - Learn how to embed components (Swift & Objective-C examples)
- **Swift**: [Swift Developer Guide](./guides/developer-guide.md) - Comprehensive patterns and examples
- **Objective-C**: [Objective-C Developer Guide](./guides/objective-c-guide.md) - Complete Objective-C guide with API reference

---

**Recommendation**: Start with high-level APIs. They cover 95% of use cases with minimal code. Only use low-level APIs if you have specific requirements that high-level APIs cannot meet.

**Language Support**: 
- **Swift**: Full support with async/await and Combine
- **Objective-C**: Full support via `CKT`-prefixed wrapper classes with delegate-based patterns

