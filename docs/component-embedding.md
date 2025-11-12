# Component Embedding Guide

ChatKit components are designed to be container-agnostic. They can be embedded in navigation controllers, modal sheets, drawers, tab bars, and any other container without assumptions about their parent.

---

## Component Philosophy

### Container-Agnostic Design

ChatKit components (`ChatKitConversationViewController`, `ChatKitConversationListViewController`) make no assumptions about:
- Parent container type
- Navigation structure
- Presentation style
- Layout constraints

This allows you to embed them in any scenario that fits your app's design.

### Key Components

#### ChatKitConversationViewController
Ready-made chat UI component with:
- Message rendering (user and agent messages)
- Input composer with rich text support
- Typing indicators
- Status banner
- Welcome message support
- Context providers integration
- Tool selector integration

#### ChatKitConversationListViewController
Ready-made conversation list component with:
- Conversation list with metadata
- Search functionality
- Swipe-to-delete
- Long-press actions
- New conversation button
- Customizable header

---

## Embedding Scenarios

### 1. Navigation Controller (Full Screen)

The most common pattern - full-screen chat in a navigation stack.

#### Swift

```swift
// Create conversation
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)

// Create chat view controller
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// Push onto navigation stack
navigationController?.pushViewController(chatVC, animated: true)
```

#### Objective-C

```objc
[self.coordinator startConversationWithAgentId:agentId
                                          title:nil
                                      agentName:@"My Agent"
                                     completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) return;
    
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

**Use case**: Standard chat app with navigation-based flow.

---

### 2. Modal Sheet Presentation

Present chat as a modal sheet (iOS 15+ style).

#### Swift

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// Configure as sheet
if let sheet = chatVC.sheetPresentationController {
    sheet.detents = [.medium(), .large()]
    sheet.prefersGrabberVisible = true
}

// Present modally
present(chatVC, animated: true)
```

#### Objective-C

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];

// Configure as sheet (iOS 15+)
if (@available(iOS 15.0, *)) {
    UISheetPresentationController *sheet = chatVC.sheetPresentationController;
    if (sheet) {
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent, 
                          UISheetPresentationControllerDetent.largeDetent];
        sheet.prefersGrabberVisible = YES;
    }
}

// Present modally
[self presentViewController:chatVC animated:YES completion:nil];
```

**Use case**: Quick chat overlay, temporary conversations, help/support chat.

---

### 3. Drawer/Sidebar Container

Embed chat in a drawer or sidebar (like the Simple app).

#### Swift

```swift
class DrawerContainerViewController: UIViewController {
    private let coordinator: ChatKitCoordinator
    private var currentChatVC: ChatKitConversationViewController?
    
    init(coordinator: ChatKitCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    func showConversation(record: ConversationRecord, conversation: Conversation) {
        // Remove existing chat
        if let existing = currentChatVC {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
        }
        
        // Create and add new chat
        let chatVC = ChatKitConversationViewController(
            record: record,
            conversation: conversation,
            coordinator: coordinator,
            configuration: .default
        )
        
        addChild(chatVC)
        view.addSubview(chatVC.view)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        currentChatVC = chatVC
    }
}
```

#### Objective-C

```objc
@interface DrawerContainerViewController : UIViewController
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) ChatKitConversationViewController *currentChatVC;
@end

@implementation DrawerContainerViewController

- (void)showConversation:(CKTConversationRecord *)record conversation:(id)conversation {
    // Remove existing chat
    if (self.currentChatVC) {
        [self.currentChatVC willMoveToParentViewController:nil];
        [self.currentChatVC.view removeFromSuperview];
        [self.currentChatVC removeFromParentViewController];
    }
    
    // Create and add new chat
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    ChatKitConversationViewController *chatVC = 
        [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                             conversation:conversation
                                                          objcCoordinator:self.coordinator
                                                        objcConfiguration:config];
    
    [self addChildViewController:chatVC];
    [self.view addSubview:chatVC.view];
    chatVC.view.translatesAutoresizingMaskIntoConstraints = NO;
    [chatVC didMoveToParentViewController:self];
    
    [NSLayoutConstraint activateConstraints:@[
        [chatVC.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [chatVC.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [chatVC.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [chatVC.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
    
    self.currentChatVC = chatVC;
}

@end
```

**Use case**: Multi-conversation apps with side navigation, drawer-based UIs.

**See**: 
- `demo-apps/iOS/Simple/App/ViewControllers/DrawerContainerViewController.swift` - Swift example
- `demo-apps/iOS/SimpleObjC/` - Objective-C patterns

---

### 4. Tab Bar Item

Embed chat as a tab in a tab bar controller.

#### Swift

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)
chatVC.tabBarItem = UITabBarItem(title: "Chat", image: UIImage(systemName: "message"), tag: 0)

let tabBarController = UITabBarController()
tabBarController.viewControllers = [chatVC, otherViewController]
```

#### Objective-C

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];
chatVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Chat" 
                                                   image:[UIImage systemImageNamed:@"message"] 
                                                     tag:0];

UITabBarController *tabBarController = [[UITabBarController alloc] init];
tabBarController.viewControllers = @[chatVC, otherViewController];
```

**Use case**: Multi-feature apps with chat as one feature.

---

### 5. Split View Controller (iPad)

Embed in split view for iPad apps.

#### Swift

```swift
// Master: Conversation list
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)

// Detail: Chat view
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

let splitVC = UISplitViewController()
splitVC.viewControllers = [
    UINavigationController(rootViewController: listVC),
    UINavigationController(rootViewController: chatVC)
]
```

#### Objective-C

```objc
// Master: Conversation list
CKTConversationListConfiguration *listConfig = [CKTConversationListConfiguration defaultConfiguration];
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:listConfig];

// Detail: Chat view
CKTConversationConfiguration *chatConfig = [CKTConversationConfiguration defaultConfiguration];
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:chatConfig];

UISplitViewController *splitVC = [[UISplitViewController alloc] init];
splitVC.viewControllers = @[
    [[UINavigationController alloc] initWithRootViewController:listVC],
    [[UINavigationController alloc] initWithRootViewController:chatVC]
];
```

**Use case**: iPad apps with master-detail layout.

---

### 6. Popover (iPad)

Present chat in a popover.

#### Swift

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

chatVC.modalPresentationStyle = .popover
if let popover = chatVC.popoverPresentationController {
    popover.sourceView = sourceButton
    popover.sourceRect = sourceButton.bounds
    popover.permittedArrowDirections = .up
}

present(chatVC, animated: true)
```

#### Objective-C

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];

chatVC.modalPresentationStyle = UIModalPresentationPopover;
UIPopoverPresentationController *popover = chatVC.popoverPresentationController;
if (popover) {
    popover.sourceView = sourceButton;
    popover.sourceRect = sourceButton.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
}

[self presentViewController:chatVC animated:YES completion:nil];
```

**Use case**: Contextual chat, quick help, inline assistance.

---

## Conversation List Embedding

### Drawer/Sidebar

The most common pattern for conversation lists.

#### Swift

```swift
class DrawerViewController: ChatKitConversationListViewController {
    weak var drawerDelegate: DrawerViewControllerDelegate?
    
    init(coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationListConfiguration.default
        config.headerTitle = "Conversations"
        config.showSearchBar = true
        config.showNewButton = true
        config.enableSwipeToDelete = true
        
        super.init(coordinator: coordinator, configuration: config)
        self.delegate = self
    }
    
    // Implement delegate methods
    func conversationListViewController(
        _ controller: ChatKitConversationListViewController,
        didSelectConversation record: ConversationRecord
    ) {
        drawerDelegate?.drawerDidSelectConversation(sessionId: record.id)
    }
}
```

**See**: `demo-apps/iOS/Simple/App/ViewControllers/DrawerViewController.swift` for complete example.

---

### Tab Bar Item

#### Swift

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)
listVC.tabBarItem = UITabBarItem(title: "Chats", image: UIImage(systemName: "list.bullet"), tag: 0)
```

#### Objective-C

```objc
CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:config];
listVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Chats" 
                                                  image:[UIImage systemImageNamed:@"list.bullet"] 
                                                    tag:0];
```

---

### Navigation Controller

#### Swift

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)
navigationController?.pushViewController(listVC, animated: true)
```

#### Objective-C

```objc
CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:config];
[self.navigationController pushViewController:listVC animated:YES];
```

---

## Custom Container Patterns

### Drawer Container Pattern

The Simple app demonstrates a drawer container pattern:

```
DrawerContainerViewController
├── DrawerViewController (ChatKitConversationListViewController)
│   └── Side drawer with conversation list
└── MainChatViewController
    └── ChatKitConversationViewController
        └── Main chat area
```

**Key points**:
- Drawer slides over main content
- Tapping conversation in drawer switches main chat
- Both components are independent and reusable

**See**: `demo-apps/iOS/Simple/App/ViewControllers/DrawerContainerViewController.swift`

---

### Tab-Based Navigation

```
UITabBarController
├── Tab 1: ChatKitConversationListViewController
├── Tab 2: ChatKitConversationViewController
└── Tab 3: Other features
```

**Key points**:
- Each tab is independent
- Can switch between conversations and chat
- Simple navigation pattern

---

### Split View (iPad)

```
UISplitViewController
├── Master: ChatKitConversationListViewController
└── Detail: ChatKitConversationViewController
```

**Key points**:
- Master shows conversation list
- Detail shows selected conversation
- Automatic layout adaptation

---

## Configuration

### ChatKitConversationConfiguration

Customize chat UI behavior:

#### Swift

```swift
var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "Hello! How can I help?" }
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0

// Context providers
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [LocationContextProvider(), CalendarContextProvider()]
    }
}

// Tools
config.toolsProvider = { [Tool1(), Tool2()] }

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

#### Objective-C

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;
config.welcomeMessageProvider = ^NSString * _Nullable {
    return @"Hello! How can I help?";
};
config.statusBannerAutoHide = YES;
config.statusBannerAutoHideDelay = 2.0;

// Context providers
config.contextProvidersProvider = ^NSArray * _Nonnull {
    return @[[[LocationContextProvider alloc] init], [[CalendarContextProvider alloc] init]];
};

// Tools
config.toolsProvider = ^NSArray * _Nonnull {
    return @[[[Tool1 alloc] init], [[Tool2 alloc] init]];
};

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];
```

### ChatKitConversationListConfiguration

Customize list UI behavior:

#### Swift

```swift
var config = ChatKitConversationListConfiguration.default
config.headerTitle = "My Chats"
config.headerIcon = UIImage(systemName: "message.fill")
config.searchPlaceholder = "Search conversations..."
config.showHeader = true
config.showSearchBar = true
config.showNewButton = true
config.enableSwipeToDelete = true
config.enableLongPress = true
config.rowHeight = 72.0

let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

#### Objective-C

```objc
CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
config.headerTitle = @"My Chats";
config.headerIcon = [UIImage systemImageNamed:@"message.fill"];
config.searchPlaceholder = @"Search conversations...";
config.showHeader = YES;
config.showSearchBar = YES;
config.showNewButton = YES;
config.enableSwipeToDelete = YES;
config.enableLongPress = YES;
config.rowHeight = 72.0;

ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:config];
```

---

## Lifecycle Management

### View Controller Lifecycle

ChatKit components handle their own lifecycle automatically:

- **viewDidLoad**: Component initializes
- **viewWillAppear**: Component prepares for display
- **viewWillDisappear**: Component cleans up if needed
- **deinit**: Component releases resources

**You don't need to manage**: Binding/unbinding, adapter lifecycle, conversation state.

### Memory Management

Components automatically:
- Release resources when not visible
- Manage conversation bindings
- Clean up subscriptions
- Handle background/foreground transitions

---

## Best Practices

### 1. Reuse Components

Create components once and reuse:

```swift
// ✅ GOOD: Reuse component
private var chatVC: ChatKitConversationViewController?

func showConversation(record: ConversationRecord, conversation: Conversation) {
    if chatVC == nil {
        chatVC = ChatKitConversationViewController(...)
    }
    // Update with new conversation
}
```

### 2. Proper Container Management

Use standard view controller containment:

```swift
// ✅ GOOD: Proper containment
addChild(chatVC)
view.addSubview(chatVC.view)
chatVC.didMove(toParent: self)

// ❌ BAD: Direct view addition
view.addSubview(chatVC.view) // Missing containment calls
```

### 3. Configuration Per Use Case

Different configurations for different scenarios:

```swift
// Full-screen chat
var fullScreenConfig = ChatKitConversationConfiguration.default
fullScreenConfig.showStatusBanner = true

// Sheet chat
var sheetConfig = ChatKitConversationConfiguration.default
sheetConfig.showStatusBanner = false // Less intrusive in sheet
```

---

## Examples

### Complete Drawer Pattern
See: `demo-apps/iOS/Simple/App/ViewControllers/`

### Objective-C Patterns
See: `demo-apps/iOS/SimpleObjC/App/ViewControllers/`

---

## Next Steps

- **[Quick Start Guide](./quick-start.md)** - Get started with components (Swift & Objective-C)
- **[API Levels Guide](./api-levels.md)** - Understand component APIs
- **Swift**: [Swift Developer Guide](./guides/developer-guide.md) - Comprehensive patterns
- **Objective-C**: [Objective-C Developer Guide](./guides/objective-c-guide.md) - Complete Objective-C guide

---

**Key Takeaway**: ChatKit components are designed to work anywhere. Embed them in whatever container structure fits your app's design. All examples above are provided in both Swift and Objective-C.

