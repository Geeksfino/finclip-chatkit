# Context Providers Guide

This guide explains how to implement custom context providers for ChatKit, allowing users to attach various types of context (photos, locations, files, notes, etc.) to their messages. Context providers are "mini programs" that give you complete control over the user experience for collecting, previewing, and displaying context.

> **📘 Note:** Context providers are built on top of ConvoUI's context provider system. This guide covers both Swift and Objective-C implementations.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Implementing a Context Provider](#implementing-a-context-provider)
4. [The Three Components](#the-three-components)
5. [Registration in ChatKit](#registration-in-chatkit)
6. [Complete Examples](#complete-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What Are Context Providers?

Context providers enable users to attach rich context to their messages. Each provider consists of three UI components:

1. **Collector View** - UI for selecting/creating context (e.g., photo picker, location map, text input)
2. **Preview Chip** - Small preview shown in composer (e.g., photo thumbnail, location icon, note preview)
3. **Detail View** - Full-screen view when user taps preview chip (e.g., full image, map with details, full note)

### Key Benefits

- **Maximum Flexibility** - Complete control over all three UI components
- **Self-Contained** - Each provider is a reusable "mini program"
- **Community-Driven** - Share providers via GitHub, Swift Package Manager, CocoaPods
- **Framework Handles Plumbing** - Tap gestures, presentation, provider lookup all automatic
- **Works with ChatKit** - Seamlessly integrates with `ChatKitConversationViewController`

### Example Use Cases

- **Photos** - Select from library, show thumbnail, full-screen preview
- **Location** - Map picker, location chip with icon, detailed map view
- **Notes** - Text input, note chip, full note display
- **Stock Quotes** - Symbol picker, price chip with trend, detailed chart
- **Health Metrics** - Metric selector, value chip with color coding, trend graph
- **Video/Audio** - Media picker, thumbnail with duration, playback view
- **Documents** - File picker, icon chip, document viewer
- **Calendar Events** - Date picker, event chip, full event details

---

## Architecture

### Protocol Structure

ChatKit uses ConvoUI's context provider system. You implement the `ConvoUIContextProvider` protocol:

```swift
@available(iOS 15.0, *)
public protocol ConvoUIContextProvider {
    // Provider identification
    var id: String { get }
    var title: String { get }
    var iconName: String { get }
    var isAvailable: Bool { get }
    var priority: Int { get }
    var maximumAttachmentCount: Int { get }
    var shouldUseContainerPanel: Bool { get }
    
    // Context collection
    func makeContext() async throws -> (any ConvoUIContextItem)?
    func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView?
    
    // Preview and detail
    func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView?
    func localizedDescription(for item: any ConvoUIContextItem) -> String
}
```

### Context Item Structure

Each context item represents a piece of attached context:

```swift
@available(iOS 15.0, *)
public protocol ConvoUIContextItem: Identifiable {
    var id: UUID { get }
    var providerId: String { get }  // Links back to provider
    var type: String { get }        // e.g., "image", "location", "note"
    var displayName: String { get }
    
    // Optional custom preview (if nil, framework uses default)
    func createPreviewView(onRemove: @escaping () -> Void) -> UIView?
    
    // Encoding for transport
    func encodeForTransport() throws -> Data
    var encodingRepresentation: ConvoUIEncodingType { get }
    var encodingMetadata: [String: String]? { get }
}
```

### Framework Responsibilities

The framework automatically handles:

- ✅ **Tap Gestures** - Adds tap handling to preview chips (including custom ones)
- ✅ **Provider Lookup** - Finds provider by `providerId` when chip is tapped
- ✅ **Presentation** - Wraps detail views in page sheets
- ✅ **Scroll Handling** - Ensures chips scroll while remaining tappable
- ✅ **Remove Buttons** - Handles remove button taps independently
- ✅ **Encoding** - Sends encoded context to backend when message is sent

---

## Implementing a Context Provider

### Step 1: Create Provider Class

**Swift:**

```swift
import UIKit
import ConvoUI

@available(iOS 15.0, *)
final class MyContextProvider: ConvoUIContextProvider {
    var id: String { "my_provider" }
    var title: String { "My Context" }
    var iconName: String { "star.fill" }
    var isAvailable: Bool { true }
    var priority: Int { 100 }
    var maximumAttachmentCount: Int { 5 }
    var shouldUseContainerPanel: Bool { true }
    
    // Implement methods below...
}
```

**Objective-C:**

```objc
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ConvoUI/FinConvoComposerContextProvider.h>

@interface MyContextProvider : NSObject <FinConvoComposerContextProvider>
@end
```

### Step 2: Implement Context Collection

Choose one approach:

**Option A: Simple async method** (for programmatic collection):
```swift
func makeContext() async throws -> (any ConvoUIContextItem)? {
    // Collect context programmatically
    let data = await collectData()
    return MyContextItem(data: data)
}
```

**Option B: Custom collector view** (for UI-based collection):
```swift
func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView? {
    let collector = MyCollectorView()
    collector.onConfirm = onConfirm
    return collector
}

func makeContext() async throws -> (any ConvoUIContextItem)? {
    return nil  // Not used when createCollectorView is implemented
}
```

### Step 3: Create Context Item

**Swift:**

```swift
@available(iOS 15.0, *)
struct MyContextItem: ConvoUIContextItem {
    let id = UUID()
    let providerId = "my_provider"  // Must match provider.id
    let type = "my_type"
    var displayName: String { "My Context" }
    
    let data: MyDataType
    
    // Optional: Custom preview chip
    func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
        // Return custom view, or nil to use framework default
        return nil
    }
    
    // Encoding
    func encodeForTransport() throws -> Data {
        // Encode data for network transport
        return try JSONEncoder().encode(data)
    }
    
    var encodingRepresentation: ConvoUIEncodingType { .json }
    var encodingMetadata: [String: String]? { nil }
}
```

**Objective-C:**

```objc
@interface MyContextItem : FinConvoContextItem <FinConvoContextItemEncoding, FinConvoContextItemPreview>
@property (nonatomic, strong) NSString *myData;
@end

@implementation MyContextItem

- (instancetype)initWithData:(NSString *)data {
    self = [super init];
    if (self) {
        _myData = data;
        self.contextId = [[NSUUID UUID] UUIDString];
        self.contextType = @"my_type";
        self.providerId = @"my_provider";
        self.displayName = @"My Context";
        
        // ⚠️ CRITICAL: Set encoding handler so framework uses your encoding methods
        // Without this, the context item won't be encoded and sent to the backend!
        self.encodingHandler = self;
        
        // ⚠️ CRITICAL: Set preview handler if using custom preview view
        self.previewHandler = self;
    }
    return self;
}

// Implement encoding methods
- (NSData *)encodeForTransport:(NSError **)error {
    NSDictionary *payload = @{ @"data": self.myData };
    return [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
}

- (FinConvoContextEncoding)encodingRepresentation {
    return FinConvoContextEncodingJSON;
}

@end
```

**⚠️ Critical for Objective-C:** You **must** set `self.encodingHandler = self;` in the initializer. Without this, the framework will not encode your context item and it won't be sent to the backend!

### Step 4: Implement Detail View

```swift
func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
    guard let myItem = item as? MyContextItem else { return nil }
    
    let detailView = MyDetailView(item: myItem)
    detailView.onDismiss = onDismiss
    
    // If using a view controller, retain it:
    // let controller = MyDetailViewController(item: myItem, onDismiss: onDismiss)
    // objc_setAssociatedObject(controller.view, "viewController", controller, .OBJC_ASSOCIATION_RETAIN)
    // return controller.view
    
    return detailView
}
```

---

## Registration in ChatKit

### Swift: Using ChatKitConversationConfiguration

```swift
import FinClipChatKit
import ConvoUI

final class ChatViewController: ChatKitConversationViewController {
    init(record: ConversationRecord, conversation: Conversation, coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationConfiguration.default
        config.showStatusBanner = true
        config.showWelcomeMessage = true
        
        // Register context providers
        config.contextProvidersProvider = {
            MainActor.assumeIsolated {
                [
                    ConvoUIContextProviderBridge(provider: LocationContextProvider()),
                    ConvoUIContextProviderBridge(provider: CalendarContextProvider()),
                    ConvoUIContextProviderBridge(provider: MyContextProvider())
                ]
            }
        }
        
        super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
    }
}
```

### Objective-C: Direct Registration

Since `CKTConversationConfiguration` doesn't expose `contextProvidersProvider` (it's a Swift closure), register providers directly on the chat view:

```objc
#import "MyContextProvider.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>
#import <ConvoUI/FinConvoMessageInputView.h>

// After creating ChatKitConversationViewController:
ChatKitConversationViewController *chatVC = [[ChatKitConversationViewController alloc] 
    initWithObjCRecord:record
    conversation:conversation
    objcCoordinator:coordinator
    objcConfiguration:config];

// Register context providers directly on the chat view
dispatch_async(dispatch_get_main_queue(), ^{
    // Load the view if needed to ensure chatView is available
    [chatVC loadViewIfNeeded];
    
    if (@available(iOS 15.0, *)) {
        MyContextProvider *myProvider = [[MyContextProvider alloc] init];
        chatVC.chatView.inputView.contextProviders = @[myProvider];
        chatVC.chatView.inputView.contextPickerEnabled = YES;
        chatVC.chatView.inputView.contextPickerMaxItems = 3;
    }
    [self.navigationController pushViewController:chatVC animated:YES];
});
```

---

## The Three Components

### 1. Collector View

The collector view is shown when the user selects your provider from the context picker menu.

**When to use `createCollectorView`:**
- User needs to interact with UI to select context
- Examples: Photo picker, map selector, file browser, date picker, text input

**When to use `makeContext`:**
- Context can be collected programmatically
- Examples: Current location, device info, clipboard content

**Example Collector View (Swift):**

```swift
class MyCollectorView: UIView {
    var onConfirm: (((any ConvoUIContextItem)?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Add your UI components
        let button = UIButton(type: .system)
        button.setTitle("Select Context", for: .normal)
        button.addTarget(self, action: #selector(handleSelect), for: .touchUpInside)
        addSubview(button)
        
        // Layout...
    }
    
    @objc private func handleSelect() {
        // Create context item
        let item = MyContextItem(data: collectedData)
        onConfirm?(item)
    }
}
```

### 2. Preview Chip

The preview chip appears in the composer area above the text input, showing attached context.

**Framework Default Behavior:**

If `createPreviewView` returns `nil`, the framework provides defaults:

- **Image type** (`type == "image"`): 44x44 thumbnail with remove button
- **Other types**: Text chip with `displayName` and remove button

**Custom Preview:**

Return a custom view for distinctive styling. The framework automatically adds tap handling:

```swift
func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
    container.backgroundColor = .systemBlue.withAlphaComponent(0.1)
    container.layer.cornerRadius = 8
    
    // Icon
    let icon = UILabel(frame: CGRect(x: 8, y: 10, width: 20, height: 20))
    icon.text = "📍"
    container.addSubview(icon)
    
    // Label
    let label = UILabel(frame: CGRect(x: 32, y: 0, width: 40, height: 40))
    label.text = displayName
    container.addSubview(label)
    
    // Remove button
    let removeButton = UIButton(type: .system)
    removeButton.frame = CGRect(x: 60, y: 10, width: 20, height: 20)
    removeButton.setTitle("✕", for: .normal)
    removeButton.addAction(UIAction { _ in onRemove() }, for: .touchUpInside)
    container.addSubview(removeButton)
    
    return container
}
```

**Important Notes:**

- ✅ Framework automatically adds tap gesture to open detail view
- ✅ Framework handles scroll view interactions
- ✅ Remove button works independently
- ✅ No need to manage tap gestures yourself

### 3. Detail View

The detail view is shown when the user taps a preview chip.

**Simple UIView Approach:**

```swift
class MyDetailView: UIView {
    var onDismiss: (() -> Void)?
    
    init(item: MyContextItem) {
        super.init(frame: .zero)
        setupUI(item: item)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(item: MyContextItem) {
        backgroundColor = .systemBackground
        
        // Close button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        addSubview(closeButton)
        
        // Your content
        // ...
        
        // Layout...
    }
    
    @objc private func handleClose() {
        onDismiss?()
    }
}
```

**UIViewController Approach:**

If you need view controller lifecycle:

```swift
class MyDetailViewController: UIViewController {
    private let onDismiss: () -> Void
    
    init(item: MyContextItem, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        setupUI(item: item)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(item: MyContextItem) {
        view.backgroundColor = .systemBackground
        // Setup UI...
    }
    
    @objc private func handleClose() {
        onDismiss()
    }
}

// In provider:
func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
    guard let myItem = item as? MyContextItem else { return nil }
    
    let controller = MyDetailViewController(item: myItem, onDismiss: onDismiss)
    
    // CRITICAL: Retain the controller
    objc_setAssociatedObject(controller.view, "viewController", controller, .OBJC_ASSOCIATION_RETAIN)
    
    return controller.view
}
```

---

## Complete Examples

### Swift Examples

**Location Provider:**
- See `demo-apps/iOS/Simple/App/Extensions/LocationContextProvider.swift`
- Custom collector view with `MKMapView` and search
- Custom preview chip with 📍 icon
- Custom detail view with map

**Calendar Provider:**
- See `demo-apps/iOS/Simple/App/Extensions/CalendarContextProvider.swift`
- Custom collector view with event list
- Custom preview chip with calendar icon
- Custom detail view with event details

### Objective-C Example

**Note Provider:**
- See `demo-apps/iOS/SimpleObjC/App/ContextProviders/NoteContextProvider.h/m`
- Complete Objective-C implementation demonstrating:
  - Custom collector view (text input)
  - Custom preview chip (styled note preview)
  - Custom detail view (full note display)
  - Proper encoding with `encodingHandler` set
  - Registration in `ConversationListViewController`

---

## Best Practices

### 1. Provider Identification

**Always set unique `providerId`:**

```swift
// In provider
var id: String { "my_unique_provider_id" }

// In context item
let providerId = "my_unique_provider_id"  // Must match!
```

This ensures the framework can correctly match items to providers when showing detail views.

### 2. Encoding Handler (Critical!)

**⚠️ Most Common Issue:** Context items not being sent to backend.

**For Swift:** The framework automatically uses your encoding methods when you implement `ConvoUIContextItem`.

**For Objective-C:** You **must** set the `encodingHandler` property:

```objc
// In your context item's init method:
self.encodingHandler = self;  // REQUIRED for encoding to work!
```

**Why this is needed:**

The framework checks `item.encodingHandler` to determine if it should encode the context item. If `encodingHandler` is `nil`, the framework assumes the item doesn't need encoding and won't call your `encodeForTransport:` method.

**Verification Checklist:**

- ✅ `encodingHandler` is set to `self` in initializer (Objective-C)
- ✅ Context item conforms to `FinConvoContextItemEncoding` protocol (Objective-C) or `ConvoUIContextItem` (Swift)
- ✅ `encodeForTransport:` returns valid `NSData` (Objective-C) or `Data` (Swift)
- ✅ `encodingRepresentation` returns correct encoding type
- ✅ Test by sending a message and checking backend receives context

### 3. Preview Chip Design

**Guidelines:**
- Keep chips compact (36-80pt width, 36-44pt height)
- Use clear visual indicators (icons, colors)
- Ensure remove button is easily tappable
- Test in scroll view (chips scroll horizontally)

**Accessibility:**
- Set `accessibilityLabel` on custom preview views
- Ensure sufficient contrast
- Support Dynamic Type if using text

### 4. Detail View Lifecycle

**If using UIViewController:**
- Always retain the controller using `objc_setAssociatedObject`
- Call `onDismiss()` when user closes
- Don't present modally yourself (framework handles it)

**If using UIView:**
- Implement `onDismiss` callback
- Handle layout constraints properly
- Support safe areas

### 5. Error Handling

**Collection errors:**
```swift
func makeContext() async throws -> (any ConvoUIContextItem)? {
    do {
        let data = try await collectData()
        return MyContextItem(data: data)
    } catch {
        // Log error, show alert, or return nil
        return nil
    }
}
```

### 6. Performance

**Lazy Loading:**
- Don't load heavy data until detail view is shown
- Use thumbnails for preview chips
- Compress images before encoding

**Memory Management:**
- Release resources when detail view dismisses
- Use weak references in closures
- Clear caches appropriately

### 7. Localization

**Provider metadata:**
```swift
var title: String { 
    NSLocalizedString("context.my_provider", comment: "My Provider")
}
```

**Context descriptions:**
```swift
func localizedDescription(for item: any ConvoUIContextItem) -> String {
    // Return localized description for fallback text preview
    return NSLocalizedString("context.my_provider.description", comment: "")
}
```

---

## Troubleshooting

### Preview Chip Not Tappable

**Problem:** Tapping preview chip doesn't open detail view.

**Solutions:**
- Ensure `providerId` matches between provider and item
- Check that `createDetailView` returns a non-nil view
- Verify framework has added tap gesture (check logs)
- Ensure custom preview view has `userInteractionEnabled = true`

### Detail View Not Showing

**Problem:** Detail view doesn't appear when tapping chip.

**Solutions:**
- Check provider lookup logs to verify provider is found
- Ensure `createDetailView` is implemented
- If using UIViewController, verify controller is retained
- Check that `onDismiss` callback is properly wired

### Custom Preview Not Appearing

**Problem:** Custom preview chip not shown, default used instead.

**Solutions:**
- Verify `createPreviewView` returns non-nil view
- Check view has valid frame or constraints
- Ensure view is properly configured before return
- Test with framework's default first, then add custom

### Remove Button Not Working

**Problem:** Remove button (×) doesn't remove context item.

**Solutions:**
- Verify `onRemove` callback is called
- Check button is not covered by other views
- Ensure button is added to preview view hierarchy
- Test with framework's default preview first

### Provider Not in Menu

**Problem:** Provider doesn't appear in context picker menu.

**Solutions:**
- Check `isAvailable` returns `true`
- Verify provider is added to `contextProviders` array
- Ensure `contextPickerEnabled` is `true`
- Check `priority` value (higher = appears first)

### Context Not Being Sent to Backend

**Problem:** Context item appears in UI but isn't included in message sent to backend.

**Solutions:**
- **Objective-C:** Verify `encodingHandler` is set to `self` in context item's initializer
- Check that context item conforms to `FinConvoContextItemEncoding` protocol (Objective-C) or `ConvoUIContextItem` (Swift)
- Verify `encodeForTransport:` method returns valid `NSData` (not nil)
- Check `encodingRepresentation` returns correct encoding type
- Test encoding method directly: `NSData *data = [item.encodingHandler encodeForTransport:&error];` (Objective-C)
- Check framework logs for encoding errors
- Verify `item.encodingHandler` is not `nil` when message is sent (Objective-C)

**Common Mistakes:**
- ❌ Forgetting to set `self.encodingHandler = self;` in Objective-C
- ❌ `encodeForTransport:` returning `nil` or throwing error
- ❌ Not conforming to `FinConvoContextItemEncoding` protocol (Objective-C)
- ❌ Setting `encodingHandler` after item is created (must be in `init`)

---

## Related Documentation

- **[Developer Guide](./developer-guide.md)** - Complete ChatKit development guide
- **[Objective-C Guide](./objective-c-guide.md)** - Objective-C specific patterns
- **[Composer Customization](../../how-to/customize-ui.md)** - Overview of composer features
- **[Examples](../../../demo-apps/iOS/)** - Working examples in demo apps

---

## Demo Apps

Complete working examples are available in the demo apps:

- **Simple (Swift):** `demo-apps/iOS/Simple/App/Extensions/`
  - `LocationContextProvider.swift`
  - `CalendarContextProvider.swift`
  
- **SimpleObjC (Objective-C):** `demo-apps/iOS/SimpleObjC/App/ContextProviders/`
  - `NoteContextProvider.h/m` - Complete Objective-C example

---

**Last Updated**: November 2025  
**ChatKit Version**: 0.9.0+

