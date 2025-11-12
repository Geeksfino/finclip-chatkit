# Getting Started with ChatKit

Welcome to ChatKit! This guide provides language-specific quick starts to get you up and running in minutes.

> 🚀 **Want minimal code?** See the [Quick Start Guide](./quick-start.md) for skeleton templates (5 minutes).
> 
> 📚 **Looking for comprehensive guides?**
> - **Swift**: [Swift Developer Guide](./guides/developer-guide.md)
> - **Objective-C**: [Objective-C Developer Guide](./guides/objective-c-guide.md)

---

## Choose Your Language

- **[Swift Quick Start](#swift-quick-start)** - Swift developers start here
- **[Objective-C Quick Start](#objective-c-quick-start)** - Objective-C developers start here

---

## Swift Quick Start

### Prerequisites

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **Swift 5.9+**

### 1. Add ChatKit Dependency

Create or update your `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyAIChat",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
    ],
    targets: [
        .target(
            name: "MyAIChat",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)
```

### 2. Initialize Coordinator (Do This Once!)

**IMPORTANT**: Initialize coordinator at app launch, but don't create conversations yet.

```swift
import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // 1. Create configuration
        let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
            .withUserId("demo-user")
        
        // 2. Initialize ChatKitCoordinator (creates runtime once)
        let coordinator = ChatKitCoordinator(config: config)
        
        // 3. Show main UI (with empty state or conversation list)
        let mainVC = MainViewController(coordinator: coordinator)
        window.rootViewController = UINavigationController(rootViewController: mainVC)
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
```

### 3. Create Conversation and Show Chat UI

**Don't create conversations at app launch!** Wait for user action:

```swift
class MainViewController: UIViewController {
    private let coordinator: ChatKitCoordinator
    
    init(coordinator: ChatKitCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Show "New Chat" button
        let button = UIButton(type: .system)
        button.setTitle("Start New Chat", for: .normal)
        button.addTarget(self, action: #selector(startNewChat), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func startNewChat() {
        Task { @MainActor in
            // NOW create conversation (user requested it)
            let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
            
            do {
                let (record, conversation) = try await coordinator.startConversation(
                    agentId: agentId,
                    title: nil,
                    agentName: "My Agent"
                )
                
                // Show ready-made chat UI using high-level component
                let chatVC = ChatKitConversationViewController(
                    record: record,
                    conversation: conversation,
                    coordinator: coordinator,
                    configuration: .default
                )
                
                navigationController?.pushViewController(chatVC, animated: true)
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }
}
```

### That's It!

You now have a working AI chat app with:
- ✅ Persistent conversation storage
- ✅ Safe runtime lifecycle management
- ✅ Full-featured chat UI (ready-made component)
- ✅ Message history
- ✅ Minimal code (20-30 lines)

---

## Key Concepts

### The Two-Step Pattern

Understanding the difference between these steps is crucial:

#### Step 1: Coordinator Initialization (Once, at App Launch)
```swift
// Do this in AppDelegate/SceneDelegate
let config = NeuronKitConfig.default(serverURL: serverURL).withUserId("user-123")
let coordinator = ChatKitCoordinator(config: config)
```

**What happens:**
- Creates runtime instance
- Establishes server connection
- Loads persisted state
- Prepares infrastructure

**When:** App launch, once per app lifecycle

#### Step 2: Conversation Creation (Many Times, User-Initiated)
```swift
// Do this when user taps "New Chat" or selects from history
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)
```

**What happens:**
- Creates conversation session
- Associates with AI agent
- Opens chat stream
- Returns record and conversation

**When:** User requests it (button tap, select from list)

### ChatKitCoordinator

The **recommended way** to manage `NeuronRuntime` lifecycle.

**Why use it?** Creating a new runtime destroys the old one, losing all conversation state. `ChatKitCoordinator` ensures runtime persists across your app.

**Where to store it?** At app-level (AppDelegate, SceneDelegate, or root coordinator).

### Common Pitfall

```swift
// ❌ WRONG: Creates conversation too early
func application(...) -> Bool {
    let coordinator = ChatKitCoordinator(config: config)
    let conversation = try await coordinator.startConversation(...) // Too soon!
    return true
}

// ✅ CORRECT: Initialize coordinator, create conversation later
func scene(...) {
    let coordinator = ChatKitCoordinator(config: config) // Just coordinator
    // Show empty state or conversation list
}

// Later, when user taps button:
@objc func newChat() {
    let (record, conversation) = try await coordinator.startConversation(...) // Now!
    let chatVC = ChatKitConversationViewController(...) // Show UI
}
```

---

## Objective-C Quick Start

### Prerequisites

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **Objective-C** project

### 1. Add ChatKit Dependency

Add to your `Package.swift` or configure in Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
]
```

### 2. Initialize Coordinator (Do This Once!)

**IMPORTANT**: Initialize coordinator at app launch, but don't create conversations yet.

```objc
#import "SceneDelegate.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session 
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // 1. Create configuration
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    
    // 2. Initialize ChatKitCoordinator (creates runtime once)
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    
    // 3. Show main UI (with empty state or conversation list)
    MainViewController *mainVC = [[MainViewController alloc] initWithCoordinator:coordinator];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainVC];
    [window makeKeyAndVisible];
    
    self.window = window;
}

@end
```

### 3. Create Conversation and Show Chat UI

**Don't create conversations at app launch!** Wait for user action:

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
    
    // Show "New Chat" button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Start New Chat" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startNewChat) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)startNewChat {
    // NOW create conversation (user requested it)
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            NSLog(@"Failed to create conversation: %@", error);
            return;
        }
        
        // Show ready-made chat UI using high-level component
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

@end
```

### That's It!

You now have a working Objective-C AI chat app with:
- ✅ Persistent conversation storage
- ✅ Safe runtime lifecycle management
- ✅ Full-featured chat UI (ready-made component)
- ✅ Message history
- ✅ Minimal code (30-40 lines)

---

## Key Concepts (Objective-C)

### The Two-Step Pattern

Understanding the difference between these steps is crucial:

#### Step 1: Coordinator Initialization (Once, at App Launch)
```objc
// Do this in AppDelegate/SceneDelegate
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent;
CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

**What happens:**
- Creates runtime instance
- Establishes server connection
- Loads persisted state
- Prepares infrastructure

**When:** App launch, once per app lifecycle

#### Step 2: Conversation Creation (Many Times, User-Initiated)
```objc
// Do this when user taps "New Chat" or selects from history
[self.coordinator startConversationWithAgentId:agentId
                                          title:nil
                                      agentName:@"My Agent"
                                     completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    // Use record and conversation
}];
```

**What happens:**
- Creates conversation session
- Associates with AI agent
- Opens chat stream
- Returns record and conversation via completion handler

**When:** User requests it (button tap, select from list)

### CKTChatKitCoordinator

The **recommended way** to manage runtime lifecycle in Objective-C.

**Why use it?** Creating a new runtime destroys the old one, losing all conversation state. `CKTChatKitCoordinator` ensures runtime persists across your app.

**Where to store it?** At app-level (AppDelegate, SceneDelegate, or root coordinator).

### Common Pitfall

```objc
// ❌ WRONG: Creates conversation too early
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    [coordinator startConversationWithAgentId:agentId ...]; // Too soon!
    return YES;
}

// ✅ CORRECT: Initialize coordinator, create conversation later
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config]; // Just coordinator
    // Show empty state or conversation list
}

// Later, when user taps button:
- (void)startNewChat {
    [self.coordinator startConversationWithAgentId:agentId ...]; // Now!
    // Show UI
}
```

---

## Next Steps

Choose your learning path:

### 📖 Want to Learn More?

**Swift Developers:**
→ Read the [Swift Developer Guide](./guides/developer-guide.md) for:
- **Part 1**: Simple chat app (detailed walkthrough)
- **Part 2**: Managing multiple conversations
- **Part 3**: Building conversation history UI

**Objective-C Developers:**
→ Read the [Objective-C Developer Guide](./guides/objective-c-guide.md) for:
- Basic usage patterns
- Multiple conversations
- Conversation list UI
- Complete API reference

### 🎯 Understand API Levels?

→ See [API Levels Guide](./api-levels.md) for:
- High-level vs low-level APIs
- When to use each
- Provider mechanisms

### 🎨 Ready to Customize?

→ See [Component Embedding Guide](./component-embedding.md) for:
- Embedding in sheets, drawers, tabs (Swift & Objective-C examples)
- Custom container patterns

→ See [Customize UI Guide](./how-to/customize-ui.md) for:
- Styling and theming

### 🔧 Set Up Builds?

→ See [Build Tooling Guide](./build-tooling.md) for:
- Makefile and XcodeGen
- Reproducible builds

### 🏗️ Understanding Architecture?

→ Check [Architecture Overview](./architecture/overview.md)

### 🔧 Having Issues?

→ Visit [Troubleshooting Guide](./troubleshooting.md)

### 🧪 Want to See Examples?

→ Explore the demos:

**Simple Demo (Swift):**
```bash
cd demo-apps/iOS/Simple
make run
```

**SimpleObjC Demo (Objective-C):**
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**Note:** These examples demonstrate high-level APIs with minimal code - perfect for learning!

---

## Quick Reference

### Minimum Viable Chat App

```swift
// 1. Initialize coordinator (once, at app launch)
let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
    .withUserId("demo-user")
let coordinator = ChatKitCoordinator(config: config)

// 2. Later, when user requests chat:
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
    configuration: .default
)
navigationController?.pushViewController(chatVC, animated: true)
```

### With Conversation Manager (Multi-Session Apps)

```swift
// 1. Initialize
let coordinator = ChatKitCoordinator(config: config)
let manager = ChatKitConversationManager()
manager.attach(runtime: coordinator.runtime)

// 2. Create conversation
let (record, conversation) = try await manager.createConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent",
    deviceId: deviceId
)

// 3. Show chat UI
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// 4. Observe updates
manager.recordsPublisher
    .sink { records in
        // Update UI with conversation list
    }
    .store(in: &cancellables)
```

---

## Support

- **Comprehensive Guide**: [Developer Guide](./developer-guide.md)
- **Examples**: `demo-apps/iOS/AI-Bank` and `demo-apps/iOS/Smart-Gov`
- **Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

Happy coding! 🚀
