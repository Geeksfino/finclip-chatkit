# Objective-C Developer Guide

Complete guide for building ChatKit applications in Objective-C. This guide covers everything from basic setup to advanced patterns, with comprehensive examples.

> **📘 New to ChatKit?** Start with the [Objective-C Quick Start](../getting-started.md#objective-c-quick-start) for a 5-minute setup.
> 
> **📘 Swift Developer?** See the [Swift Developer Guide](./developer-guide.md).

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Basic Usage](#basic-usage)
3. [Multiple Conversations](#multiple-conversations)
4. [Conversation List UI](#conversation-list-ui)
5. [Component Embedding](#component-embedding)
6. [Provider Customization](#provider-customization)
7. [API Reference](#api-reference)

---

## Quick Start

### Prerequisites

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **Objective-C** project

### Step 1: Add Dependency

Add to your `Package.swift` or configure in Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
]
```

### Step 2: Import ChatKit

In your Objective-C files:

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>
```

Or use module import:

```objc
@import FinClipChatKit;
```

### Step 3: Initialize Coordinator

In your `SceneDelegate.m` or `AppDelegate.m`:

```objc
#import "SceneDelegate.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session 
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // Initialize ChatKitCoordinator
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    
    // Create root view controller
    MainViewController *rootVC = [[MainViewController alloc] initWithCoordinator:coordinator];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    [window makeKeyAndVisible];
    
    self.window = window;
}

@end
```

### Step 4: Create Conversation and Show Chat

In your main view controller:

```objc
#import "MainViewController.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface MainViewController ()
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@end

@implementation MainViewController

- (instancetype)initWithCoordinator:(CKTChatKitCoordinator *)coordinator {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _coordinator = coordinator;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add "New Chat" button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Start Chat" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startChat) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)startChat {
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            NSLog(@"Failed to create conversation: %@", error);
            return;
        }
        
        // Show ready-made chat UI
        CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
        ChatKitConversationViewController *chatVC = 
            [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                             conversation:conversation
                                                          objcCoordinator:self.coordinator
                                                        objcConfiguration:config];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:chatVC];
            [self presentViewController:navController animated:YES completion:nil];
        });
    }];
}

@end
```

**That's it!** You now have a working Objective-C AI chat app.

---

## Basic Usage

### Understanding the Coordinator

`CKTChatKitCoordinator` is the main entry point for Objective-C developers. It manages the runtime lifecycle and provides methods to create conversations.

#### Initialization

```objc
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent; // Or CKTStorageModeInMemory

CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

#### Configuration Options

- **`serverURL`**: Your AI agent server URL (required)
- **`userId`**: Unique user identifier (required)
- **`deviceId`**: Device identifier (optional, nil = auto-generated)
- **`storageMode`**: `CKTStorageModePersistent` or `CKTStorageModeInMemory`

### Creating Conversations

Use the coordinator's `startConversationWithAgentId:title:agentName:completion:` method:

```objc
NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];

[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        // Handle error
        NSLog(@"Error: %@", error.localizedDescription);
        return;
    }
    
    // Use record and conversation
    // record: ConversationRecord with metadata (id, title, etc.)
    // conversation: Conversation instance for sending messages
}];
```

### Showing Chat UI

Use `ChatKitConversationViewController` - a ready-made component:

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;
config.welcomeMessageProvider = ^NSString * _Nullable {
    return @"Hello! How can I help?";
};

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];

[self.navigationController pushViewController:chatVC animated:YES];
```

### Configuration Options

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];

// UI Options
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;
config.welcomeMessageProvider = ^NSString * _Nullable {
    return @"Welcome!";
};

// Status Banner
config.statusBannerAutoHide = YES;
config.statusBannerAutoHideDelay = 2.0;

// Tools Provider (optional)
config.toolsProvider = ^NSArray * _Nonnull {
    // Return array of tools
    return @[];
};

// Context Providers (optional)
config.contextProvidersProvider = ^NSArray * _Nonnull {
    // Return array of context providers
    return @[];
};
```

---

## Multiple Conversations

For apps that need to manage multiple conversations, use `CKTConversationManager`.

### Setting Up the Manager

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface AppCoordinator : NSObject
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) CKTConversationManager *conversationManager;
@end

@implementation AppCoordinator

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialize coordinator
        NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
        CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                                 userId:@"demo-user"
                                                                               deviceId:nil];
        config.storageMode = CKTStorageModePersistent;
        _coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
        
        // Initialize conversation manager
        _conversationManager = [[CKTConversationManager alloc] init];
        [_conversationManager attachToCoordinator:_coordinator];
    }
    return self;
}

@end
```

### Creating Conversations

```objc
NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];

[self.conversationManager createConversationWithAgentId:agentId
                                                   title:nil
                                               agentName:@"My Agent"
                                               deviceId:nil
                                              completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        NSLog(@"Failed to create conversation: %@", error);
        return;
    }
    
    // Show chat UI
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    ChatKitConversationViewController *chatVC = 
        [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:self.coordinator
                                                    objcConfiguration:config];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:chatVC animated:YES];
    });
}];
```

### Observing Conversation Updates

Use `recordsPublisher` to observe conversation list changes:

```objc
#import <Combine/Combine.h>

@interface ConversationListViewController ()
@property (nonatomic, strong) CKTConversationManager *manager;
@property (nonatomic, strong) NSArray<CKTConversationRecord *> *records;
@property (nonatomic, strong) id<Cancellable> recordsSubscription;
@end

@implementation ConversationListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Subscribe to conversation updates
    self.recordsSubscription = [self.manager.recordsPublisher
        subscribeOn:[DispatchQueue mainQueue]
        receiveOn:[DispatchQueue mainQueue]
        sinkWithCompletion:^(NSArray<CKTConversationRecord *> *records) {
            self.records = records;
            [self.tableView reloadData];
        }];
}

- (void)dealloc {
    [self.recordsSubscription cancel];
}

@end
```

**Note**: Combine is a Swift framework. For pure Objective-C, use delegate pattern or KVO. See [Delegate Pattern](#delegate-pattern) below.

### Resuming Conversations

```objc
CKTConversationRecord *record = self.records[indexPath.row];
id conversation = [self.conversationManager conversationForSessionId:record.id];

if (conversation) {
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    ChatKitConversationViewController *chatVC = 
        [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:self.coordinator
                                                    objcConfiguration:config];
    
    [self.navigationController pushViewController:chatVC animated:YES];
}
```

### Deleting Conversations

```objc
- (void)deleteConversation:(CKTConversationRecord *)record {
    [self.conversationManager deleteConversationWithSessionId:record.id];
    // recordsPublisher will automatically emit updated list
}
```

---

## Conversation List UI

ChatKit provides `ChatKitConversationListViewController` - a ready-made conversation list component.

### Using the Ready-Made Component

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface ConversationListViewController : UIViewController <CKTConversationListViewControllerDelegate>
@property (nonatomic, strong) CKTChatKitCoordinator *coordinator;
@property (nonatomic, strong) ChatKitConversationListViewController *listViewController;
@end

@implementation ConversationListViewController

- (instancetype)initWithCoordinator:(CKTChatKitCoordinator *)coordinator {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _coordinator = coordinator;
        
        // Configure list component
        CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
        config.headerTitle = @"Conversations";
        config.searchPlaceholder = @"Search conversations...";
        config.showHeader = YES;
        config.showSearchBar = YES;
        config.showNewButton = YES;
        config.enableSwipeToDelete = YES;
        config.enableLongPress = NO;
        config.rowHeight = 72.0;
        
        // Create list view controller
        _listViewController = [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                                                      objcConfiguration:config];
        _listViewController.objcDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Embed list view controller
    [self addChildViewController:self.listViewController];
    [self.view addSubview:self.listViewController.view];
    self.listViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.listViewController didMoveToParentViewController:self];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.listViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.listViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.listViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.listViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

#pragma mark - CKTConversationListViewControllerDelegate

- (void)conversationListViewController:(ChatKitConversationListViewController *)controller
                  didSelectConversation:(CKTConversationRecord *)record {
    // User selected a conversation
    id conversation = [self.coordinator conversationForSessionId:record.id];
    
    if (conversation) {
        CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
        ChatKitConversationViewController *chatVC = 
            [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                             conversation:conversation
                                                          objcCoordinator:self.coordinator
                                                        objcConfiguration:config];
        
        [self.navigationController pushViewController:chatVC animated:YES];
    }
}

- (void)conversationListViewControllerDidRequestNewConversation:(ChatKitConversationListViewController *)controller {
    // User tapped "New" button
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            NSLog(@"Failed: %@", error);
            return;
        }
        
        CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
        ChatKitConversationViewController *chatVC = 
            [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                             conversation:conversation
                                                          objcCoordinator:self.coordinator
                                                        objcConfiguration:config];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:chatVC animated:YES];
        });
    }];
}

- (void)conversationListViewController:(ChatKitConversationListViewController *)controller
                    didPinConversation:(CKTConversationRecord *)record {
    // Handle pin action (optional)
    NSLog(@"Pin conversation: %@", record.title);
}

@end
```

### Configuration Options

```objc
CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];

// Header
config.headerTitle = @"My Chats";
config.headerIcon = [UIImage systemImageNamed:@"message.fill"];
config.showHeader = YES;

// Search
config.showSearchBar = YES;
config.searchPlaceholder = @"Search conversations...";
config.searchEnabled = YES;

// Actions
config.showNewButton = YES;
config.enableSwipeToDelete = YES;
config.enableLongPress = YES;

// Appearance
config.rowHeight = 72.0;
```

---

## Component Embedding

ChatKit components are container-agnostic. They can be embedded in navigation controllers, modal sheets, drawers, and tabs.

### Navigation Controller

```objc
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];

[self.navigationController pushViewController:chatVC animated:YES];
```

### Modal Sheet

```objc
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                         conversation:conversation
                                                      objcCoordinator:coordinator
                                                    objcConfiguration:config];

if (@available(iOS 15.0, *)) {
    UISheetPresentationController *sheet = chatVC.sheetPresentationController;
    if (sheet) {
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent, 
                          UISheetPresentationControllerDetent.largeDetent];
        sheet.prefersGrabberVisible = YES;
    }
}

[self presentViewController:chatVC animated:YES completion:nil];
```

### Drawer/Sidebar

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

### Tab Bar

```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:config];
listVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Chats" 
                                                   image:[UIImage systemImageNamed:@"list.bullet"] 
                                                     tag:0];

UITabBarController *tabBarController = [[UITabBarController alloc] init];
tabBarController.viewControllers = @[listVC, otherViewController];
```

---

## Provider Customization

### Context Providers

Attach contextual information (location, calendar events) to messages:

```objc
#import <ConvoUI/ConvoUI.h>

@interface LocationContextProvider : NSObject <FinConvoComposerContextProvider>
@end

@implementation LocationContextProvider

- (void)provideContextWithCompletion:(void (^)(FinConvoContext * _Nullable))completion {
    // Your location logic
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    // ... get location ...
    
    FinConvoContext *context = [[FinConvoContext alloc] initWithTitle:@"Current Location"
                                                               content:@"Lat: 37.7749, Lng: -122.4194"];
    completion(context);
}

@end

// Register in configuration
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.contextProvidersProvider = ^NSArray * _Nonnull {
    return @[[[LocationContextProvider alloc] init]];
};
```

### ASR Providers

Custom Automatic Speech Recognition for voice input:

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Your ASR implementation (e.g., OpenAI Whisper, Google Speech-to-Text)
    // Process audio and return transcribed text
    NSString *transcribedText = @"Transcribed text here";
    completion(transcribedText, nil);
}

- (void)cancelTranscription {
    // Cancel any ongoing requests
}

@end

// Register in configuration
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
// ASR provider registration is handled via ConvoUI configuration
```

### Title Generation Providers

Custom conversation title generation:

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

// Register when creating manager
CKTConversationManager *manager = [[CKTConversationManager alloc] initWithTitleProvider:[[MyTitleProvider alloc] init]];
```

---

## API Reference

### CKTChatKitCoordinator

Main coordinator for managing runtime and conversations.

```objc
@interface CKTChatKitCoordinator : NSObject

- (instancetype)initWithConfig:(CKTCoordinatorConfig *)config;

- (void)startConversationWithAgentId:(NSUUID *)agentId
                                title:(NSString *)title
                            agentName:(NSString *)agentName
                           completion:(void (^)(CKTConversationRecord *, id, NSError *))completion;

- (id)conversationForSessionId:(NSUUID *)sessionId;
- (void)deleteConversationWithSessionId:(NSUUID *)sessionId;

@property (nonatomic, readonly) id runtime; // NeuronRuntime (opaque)

@end
```

### CKTConversationManager

Manages multiple conversations.

```objc
@interface CKTConversationManager : NSObject

- (instancetype)init;
- (instancetype)initWithTitleProvider:(id<CKTConversationTitleProvider>)titleProvider;

- (void)attachToCoordinator:(CKTChatKitCoordinator *)coordinator;
- (void)detach;

- (void)createConversationWithAgentId:(NSUUID *)agentId
                                title:(NSString *)title
                            agentName:(NSString *)agentName
                             deviceId:(NSString *)deviceId
                           completion:(void (^)(CKTConversationRecord *, id, NSError *))completion;

- (id)conversationForSessionId:(NSUUID *)sessionId;
- (CKTConversationRecord *)recordForSessionId:(NSUUID *)sessionId;
- (void)deleteConversationWithSessionId:(NSUUID *)sessionId;

- (NSArray<CKTConversationRecord *> *)allConversations;

@property (nonatomic, readonly) id<Publisher> recordsPublisher; // Combine publisher

@end
```

### ChatKitConversationViewController

Ready-made chat UI component.

```objc
@interface ChatKitConversationViewController : UIViewController

- (instancetype)initWithObjCRecord:(CKTConversationRecord *)record
                       conversation:(id)conversation
                    objcCoordinator:(CKTChatKitCoordinator *)coordinator
                  objcConfiguration:(CKTConversationConfiguration *)configuration;

@property (nonatomic, readonly) CKTConversationRecord *record;
@property (nonatomic, readonly) NSUUID *sessionIdentifier;

@end
```

### ChatKitConversationListViewController

Ready-made conversation list component.

```objc
@interface ChatKitConversationListViewController : UIViewController

- (instancetype)initWithObjCCoordinator:(CKTChatKitCoordinator *)coordinator
                       objcConfiguration:(CKTConversationListConfiguration *)configuration;

@property (nonatomic, weak) id<CKTConversationListViewControllerDelegate> objcDelegate;

@end

@protocol CKTConversationListViewControllerDelegate <NSObject>

- (void)conversationListViewController:(ChatKitConversationListViewController *)controller
                  didSelectConversation:(CKTConversationRecord *)record;

- (void)conversationListViewControllerDidRequestNewConversation:(ChatKitConversationListViewController *)controller;

@optional
- (void)conversationListViewController:(ChatKitConversationListViewController *)controller
                    didPinConversation:(CKTConversationRecord *)record;

@end
```

---

## Common Patterns

### Delegate Pattern (Alternative to Combine)

If you prefer delegates over Combine:

```objc
@protocol ConversationManagerDelegate <NSObject>
- (void)conversationManager:(CKTConversationManager *)manager 
         didUpdateRecords:(NSArray<CKTConversationRecord *> *)records;
@end

// In your view controller
- (void)observeConversations {
    // Use KVO or polling instead of Combine
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(refreshConversations)
                                   userInfo:nil
                                    repeats:YES];
}

- (void)refreshConversations {
    NSArray<CKTConversationRecord *> *records = [self.conversationManager allConversations];
    self.records = records;
    [self.tableView reloadData];
}
```

### Error Handling

```objc
[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController 
                alertControllerWithTitle:@"Error"
                                 message:error.localizedDescription
                          preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" 
                                                      style:UIAlertActionStyleDefault 
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    
    // Success - proceed with conversation
}];
```

---

## Next Steps

- **[Swift Developer Guide](./developer-guide.md)** - See Swift examples for comparison
- **[Component Embedding Guide](../component-embedding.md)** - More embedding scenarios
- **[API Levels Guide](../api-levels.md)** - Understanding high-level vs low-level APIs
- **[SimpleObjC Demo](../../demo-apps/iOS/SimpleObjC/)** - Complete working example

---

**Ready to build?** Start with the [Objective-C Quick Start](../getting-started.md#objective-c-quick-start) →

