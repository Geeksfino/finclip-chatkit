# Getting Started with ChatKit

Welcome to ChatKit! This guide will get you up and running in minutes.

> 📚 **Looking for more?** See the [comprehensive Developer Guide](./developer-guide.md) for advanced patterns and best practices.

---

## Quick Start

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
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
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

### 2. Initialize Runtime (Do This Once!)

**IMPORTANT**: Initialize runtime at app launch, but don't create conversations yet.

```swift
import UIKit
import FinClipChatKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Store coordinator at app level - manages runtime lifecycle
    var chatCoordinator: ChatKitCoordinator!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // 1. Create configuration
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-agent-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        
        // 2. Initialize ChatKitCoordinator (creates runtime once)
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // 3. Show main UI (with empty state or conversation list)
        let mainVC = MainViewController(coordinator: chatCoordinator)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: mainVC)
        window?.makeKeyAndVisible()
        
        return true
    }
}
```

### 3. Create Conversation When User Requests It

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
        
        // Show "New Chat" button or conversation list
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
        // NOW create conversation (user requested it)
        let agentId = UUID() // Your AI agent ID
        
        let conversation = coordinator.runtime.openConversation(
            sessionId: UUID(),
            agentId: agentId
        )
        
        // Show chat UI
        let chatVC = ChatViewController(conversation: conversation)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}
```

### That's It!

You now have a working AI chat app with:
- ✅ Persistent conversation storage
- ✅ Safe runtime lifecycle management
- ✅ Full-featured chat UI
- ✅ Message history

---

## Key Concepts

### The Two-Step Pattern

Understanding the difference between these steps is crucial:

#### Step 1: Runtime Initialization (Once, at App Launch)
```swift
// Do this in AppDelegate/SceneDelegate
let coordinator = ChatKitCoordinator(config: config)
```

**What happens:**
- Creates `NeuronRuntime` instance
- Establishes server connection
- Loads persisted state
- Prepares infrastructure

**When:** App launch, once per app lifecycle

#### Step 2: Conversation Creation (Many Times, User-Initiated)
```swift
// Do this when user taps "New Chat" or selects from history
let conversation = coordinator.runtime.openConversation(sessionId: UUID(), agentId: agentId)
```

**What happens:**
- Creates conversation session
- Associates with AI agent
- Opens chat stream

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
    let conversation = coordinator.runtime.openConversation(...) // Too soon!
    return true
}

// ✅ CORRECT: Initialize runtime, create conversation later
func application(...) -> Bool {
    chatCoordinator = ChatKitCoordinator(config: config) // Just runtime
    // Show empty state or conversation list
    return true
}

// Later, when user taps button:
@objc func newChat() {
    let conversation = chatCoordinator.runtime.openConversation(...) // Now!
}
```

---

## Next Steps

Choose your learning path:

### 📖 Want to Learn More?

→ Read the [Developer Guide](./developer-guide.md) for:
- **Part 1**: Simple chat app (detailed walkthrough)
- **Part 2**: Managing multiple conversations
- **Part 3**: Building conversation history UI

### 🎨 Ready to Customize?

→ See [Customize UI Guide](./how-to/customize-ui.md)

### 🏗️ Understanding Architecture?

→ Check [Architecture Overview](./architecture/overview.md)

### 🔧 Having Issues?

→ Visit [Troubleshooting Guide](./troubleshooting.md)

### 🧪 Want to See Examples?

→ Explore the demos:

**AI-Bank Demo:**
```bash
cd demo-apps/iOS/AI-Bank
make run
```

**Smart-Gov Demo:**
```bash
cd demo-apps/iOS/Smart-Gov
make run
```

**Note:** These examples demonstrate app-level patterns (like agent management and testing modes) that are NOT part of the SDK - they're application design choices.

---

## Quick Reference

### Minimum Viable Chat App

```swift
// 1. Initialize runtime (once, at app launch)
let config = NeuronKitConfig(
    serverURL: URL(string: "https://your-server.com")!,
    deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
    userId: "user-id",
    storage: .persistent
)
let coordinator = ChatKitCoordinator(config: config)

// 2. Later, when user requests chat:
let conversation = coordinator.runtime.openConversation(
    sessionId: UUID(),
    agentId: agentId
)

// 3. Show UI
let chatVC = ChatViewController(conversation: conversation)
```

### With Conversation Manager (Multi-Session Apps)

```swift
// 1. Initialize
let coordinator = ChatKitCoordinator(config: config)
let manager = ChatKitConversationManager()
manager.attach(runtime: coordinator.runtime)

// 2. Create conversation
if let (record, conversation) = manager.createConversation(agentId: agentId) {
    let chatVC = ChatViewController(conversation: conversation)
}

// 3. Observe updates
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
