# Quick Start Guide

Get up and running with ChatKit in under 5 minutes. This guide provides **minimal skeleton code** to build your first AI chat app.

> 📚 **Want detailed explanations?** See the [Getting Started Guide](./getting-started.md) for a complete walkthrough with explanations.
> 
> 📖 **Looking for comprehensive patterns?** See the [Swift Developer Guide](./guides/developer-guide.md) or [Objective-C Developer Guide](./guides/objective-c-guide.md).
> 
> 📦 **Need installation help?** See the [Integration Guide](./integration-guide.md) for package manager setup.

---

## Swift Quick Start

### Step 1: Add Dependency

Create or update your `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyChatApp",
    platforms: [.iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
    ],
    targets: [
        .target(
            name: "MyChatApp",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)
```

### Step 2: Initialize Coordinator

In your `SceneDelegate.swift` (or `AppDelegate.swift`):

```swift
import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // Initialize ChatKitCoordinator (creates runtime once)
        let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
            .withUserId("demo-user")
        let coordinator = ChatKitCoordinator(config: config)
        
        // Create root view controller
        let rootVC = MainViewController(coordinator: coordinator)
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
```

### Step 3: Create Conversation and Show Chat

In your main view controller:

```swift
import UIKit
import FinClipChatKit

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
        
        // Add "New Chat" button
        let button = UIButton(type: .system)
        button.setTitle("Start Chat", for: .normal)
        button.addTarget(self, action: #selector(startChat), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func startChat() {
        Task { @MainActor in
            do {
                // Create conversation
                let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
                let (record, conversation) = try await coordinator.startConversation(
                    agentId: agentId,
                    title: nil,
                    agentName: "My Agent"
                )
                
                // Show chat UI using high-level component
                let chatVC = ChatKitConversationViewController(
                    record: record,
                    conversation: conversation,
                    coordinator: coordinator,
                    configuration: .default
                )
                
                let navController = UINavigationController(rootViewController: chatVC)
                present(navController, animated: true)
            } catch {
                print("Failed to create conversation: \(error)")
            }
        }
    }
}
```

**That's it!** You now have a working AI chat app with:
- ✅ Persistent conversation storage
- ✅ Full-featured chat UI
- ✅ Message history
- ✅ Safe runtime lifecycle management

---

## Objective-C Quick Start

### Step 1: Add Dependency

Add to your `Package.swift` or configure in Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
]
```

### Step 2: Initialize Coordinator

In your `SceneDelegate.m`:

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
    window.rootViewController = rootVC;
    [window makeKeyAndVisible];
    
    self.window = window;
}
@end
```

### Step 3: Create Conversation and Show Chat

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
        
        // Show chat UI using high-level component
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

## Next Steps

### Learn More
- **[Getting Started Guide](./getting-started.md)** - Detailed walkthrough with explanations (Swift & Objective-C)
- **[API Levels Guide](./api-levels.md)** - Understanding high-level vs low-level APIs
- **Swift**: [Swift Developer Guide](./guides/developer-guide.md) - Comprehensive patterns and best practices
- **Objective-C**: [Objective-C Developer Guide](./guides/objective-c-guide.md) - Complete Objective-C guide with API reference

### See Examples
- **[Running Demos](./running-demos.md)** - How to run the demo applications
- **[Simple Demo](../demo-apps/iOS/Simple/)** - Complete Swift example using high-level APIs
- **[SimpleObjC Demo](../demo-apps/iOS/SimpleObjC/)** - Complete Objective-C example

### Customize
- **[Component Embedding Guide](./component-embedding.md)** - Embed chat UI in sheets, drawers, tabs
- **[Build Tooling Guide](./build-tooling.md)** - Reproducible builds with Makefile and XcodeGen
- **[Configuration Guide](./guides/configuration.md)** - Complete configuration reference

---

## Key Concepts

### ChatKitCoordinator
Manages the runtime lifecycle. Create **once** at app launch, reuse throughout your app.

### startConversation
Creates a new conversation session. Call this when the user requests a new chat.

### ChatKitConversationViewController
Ready-made chat UI component. Handles message rendering, input, and all chat interactions automatically.

---

**Ready to build?** Start with the [Getting Started Guide](./getting-started.md) for detailed explanations →

