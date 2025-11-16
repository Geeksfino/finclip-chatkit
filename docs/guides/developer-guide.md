# Swift Developer Guide

A comprehensive guide to building conversational AI apps with ChatKit SDK in Swift, from beginner to expert.

> 🚀 **New to ChatKit?** Start with the [Swift Quick Start](../getting-started.md#swift-quick-start) for a 5-minute setup.
> 
> 📘 **Objective-C Developer?** See the [Objective-C Developer Guide](./objective-c-guide.md).

---

## Table of Contents

1. [Part 1: Getting Started - Your First AI Chat App](#part-1-getting-started)
2. [Part 2: Managing Multiple Conversations](#part-2-managing-multiple-conversations)
3. [Part 3: Building a Conversation List UI](#part-3-building-a-conversation-list-ui)
4. [API Levels and Provider Customization](#api-levels-and-provider-customization)
5. [Complete Examples](#complete-examples)

---

## Part 1: Getting Started

Build your first AI chat app in under 10 minutes.

### Prerequisites

- **Xcode 15.0+**
- **iOS 16.0+** deployment target
- **Swift 5.9+**

### Step 1: Add ChatKit Dependency

Create a `Package.swift` in your project root:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyAIChat",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
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

### Step 2: Initialize Runtime (Not Conversation Yet!)

The key pattern: **Initialize runtime early, create conversation when user takes action**.

```swift
import UIKit
import FinClipChatKit

class AppCoordinator {
    // Store coordinator at app level - it manages runtime lifecycle
    private let chatCoordinator: ChatKitCoordinator
    
    init() {
        // 1. Create configuration
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-agent-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        
        // 2. Initialize ChatKitCoordinator (creates runtime once)
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // Note: We DON'T create a conversation yet!
        // User hasn't taken action yet.
    }
    
    // Later, when user taps "New Chat" button:
    func userRequestedNewChat(agentId: UUID) async {
        // 3. NOW we create a conversation
        do {
            let (record, conversation) = try await chatCoordinator.startConversation(
                agentId: agentId,
                title: nil,
                agentName: "My Agent"
            )
            
            // 4. Show ready-made chat UI using high-level component
            let chatVC = ChatKitConversationViewController(
                record: record,
                conversation: conversation,
                coordinator: chatCoordinator,
                configuration: .default
            )
            navigationController?.pushViewController(chatVC, animated: true)
        } catch {
            print("Failed to create conversation: \(error)")
        }
    }
}
```

### Step 3: Understanding the Flow

**IMPORTANT**: Don't confuse these two steps:

1. **Runtime Initialization** (happens once at app launch)
   - Creates `ChatKitCoordinator`
   - Establishes connection to server
   - Loads any persisted state

2. **Conversation Creation** (happens when user takes action)
   - User taps "New Chat" or selects from history
   - Creates `Conversation` instance
   - Opens chat UI

### Step 4: Complete Example

Here's a minimal working app:

```swift
import UIKit
import FinClipChatKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var chatCoordinator: ChatKitCoordinator!
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize runtime
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // Show main UI with empty state
        let mainVC = MainViewController(coordinator: chatCoordinator)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: mainVC)
        window?.makeKeyAndVisible()
        
        return true
    }
}

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
        setupEmptyState()
    }
    
    private func setupEmptyState() {
        view.backgroundColor = .systemBackground
        
        // Add "New Chat" button
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

### Key Concepts

#### ChatKitCoordinator
The **recommended way** to manage `NeuronRuntime` lifecycle. It ensures:
- Runtime is created once and persists
- Safe handling of configuration changes
- Automatic cleanup when released

**Why use it?** Creating a new `NeuronRuntime` directly destroys the previous one, losing all conversation state. `ChatKitCoordinator` prevents this.

#### Runtime
The core orchestration layer (accessed via `coordinator.runtime`) that:
- Connects to your AI agent server
- Manages conversation state
- Handles message routing
- Provides conversation persistence

**Note**: You typically don't access the runtime directly. Use `ChatKitCoordinator` methods instead.

#### Conversation
Represents a single chat session. Each conversation has:
- Unique `sessionId` (UUID)
- Associated `agentId`
- Message history
- UI binding capability

**When to create?** When the user explicitly requests it (tap button, select from list), NOT during app initialization.

**How to show?** Use `ChatKitConversationViewController` - a ready-made component that handles all UI automatically.

---

## Part 2: Managing Multiple Conversations

Learn to track and switch between multiple conversation sessions.

### The Challenge

Real apps need:
- Multiple simultaneous conversation sessions
- Resume conversations from history
- Track conversation metadata (title, last message, timestamp)
- Reactive UI updates

### Solution: ChatKitConversationManager

ChatKit provides an optional `ChatKitConversationManager` that handles all this for you!

### Step 1: Set Up the Manager

```swift
import FinClipChatKit

class AppCoordinator {
    private let chatCoordinator: ChatKitCoordinator
    private let conversationManager: ChatKitConversationManager
    
    init() {
        // 1. Initialize runtime
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // 2. Initialize conversation manager
        conversationManager = ChatKitConversationManager()
        conversationManager.attach(runtime: chatCoordinator.runtime)
        
        // Manager automatically loads persisted conversations
    }
}
```

### Step 2: Create Conversations

```swift
func createNewConversation(agentId: UUID, title: String? = nil) async {
    do {
        let (record, conversation) = try await conversationManager.createConversation(
            agentId: agentId,
            title: title,
            agentName: "My Agent",
            deviceId: deviceId
        )
        
        // record: metadata (id, title, lastMessage, etc.)
        // conversation: the actual Conversation instance
        
        // Show ready-made chat UI
        let chatVC = ChatKitConversationViewController(
            record: record,
            conversation: conversation,
            coordinator: chatCoordinator,
            configuration: .default
        )
        navigationController?.pushViewController(chatVC, animated: true)
    } catch {
        print("Failed to create conversation: \(error)")
    }
}
```

### Step 3: Resume Existing Conversations

```swift
func resumeConversation(sessionId: UUID) {
    guard let conversation = conversationManager.conversation(for: sessionId),
          let record = conversationManager.record(for: sessionId) else {
        print("Conversation not found")
        return
    }
    
    // Show ready-made chat UI
    let chatVC = ChatKitConversationViewController(
        record: record,
        conversation: conversation,
        coordinator: chatCoordinator,
        configuration: .default
    )
    navigationController?.pushViewController(chatVC, animated: true)
}
```

### Step 4: Observe Conversation Updates

```swift
import Combine

class MainViewController: UIViewController {
    private let conversationManager: ChatKitConversationManager
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeConversations()
    }
    
    private func observeConversations() {
        conversationManager.recordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                // records: [ConversationRecord]
                // Sorted by lastUpdatedAt (most recent first)
                self?.updateConversationList(records)
            }
            .store(in: &cancellables)
    }
    
    private func updateConversationList(_ records: [ConversationRecord]) {
        // Update your UI with the list of conversations
        for record in records {
            print("Session: \(record.id)")
            print("Title: \(record.title)")
            print("Last message: \(record.lastMessagePreview ?? "None")")
            print("Updated: \(record.lastUpdatedDescription)") // "5 min ago"
        }
    }
}
```

### Step 5: Delete Conversations

```swift
func deleteConversation(sessionId: UUID) {
    conversationManager.deleteConversation(sessionId: sessionId)
    // Automatically removes from memory and persistent storage
    // recordsPublisher will emit updated list
}
```

### What You Get

`ChatKitConversationManager` automatically handles:

- ✅ **Conversation creation** - Creates and tracks new conversations
- ✅ **Persistence** - Saves to convstore automatically
- ✅ **Message observation** - Watches for new messages
- ✅ **Record updates** - Updates lastMessage, lastUpdatedAt
- ✅ **Auto-titling** - Uses first user message as title
- ✅ **Reactive updates** - Publishes changes via Combine
- ✅ **Memory management** - Properly unbinds UI on deletion

---

## Part 3: Building a Conversation List UI

Now let's build a conversation history view. ChatKit provides a ready-made component: `ChatKitConversationListViewController`.

### Option 1: Use Ready-Made Component (Recommended)

The easiest way is to use `ChatKitConversationListViewController`:

```swift
import UIKit
import FinClipChatKit

class MainViewController: UIViewController {
    private let coordinator: ChatKitCoordinator
    
    init(coordinator: ChatKitCoordinator) {
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create ready-made conversation list
        var config = ChatKitConversationListConfiguration.default
        config.headerTitle = "Conversations"
        config.showSearchBar = true
        config.showNewButton = true
        config.enableSwipeToDelete = true
        
        let listVC = ChatKitConversationListViewController(
            coordinator: coordinator,
            configuration: config
        )
        listVC.delegate = self
        
        // Embed in navigation controller
        addChild(listVC)
        view.addSubview(listVC.view)
        listVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            listVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            listVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            listVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        listVC.didMove(toParent: self)
    }
}

extension MainViewController: ChatKitConversationListViewControllerDelegate {
    func conversationListViewController(
        _ controller: ChatKitConversationListViewController,
        didSelectConversation record: ConversationRecord
    ) {
        // User selected a conversation - show chat
        guard let conversation = coordinator.conversation(for: record.id) else { return }
        
        let chatVC = ChatKitConversationViewController(
            record: record,
            conversation: conversation,
            coordinator: coordinator,
            configuration: .default
        )
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func conversationListViewControllerDidRequestNewConversation(
        _ controller: ChatKitConversationListViewController
    ) {
        // User tapped "New" button - create conversation
        Task { @MainActor in
            let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
            let (record, conversation) = try await coordinator.startConversation(
                agentId: agentId,
                title: nil,
                agentName: "My Agent"
            )
            
            let chatVC = ChatKitConversationViewController(
                record: record,
                conversation: conversation,
                coordinator: coordinator,
                configuration: .default
            )
            navigationController?.pushViewController(chatVC, animated: true)
        }
    }
}
```

**Benefits**:
- ✅ Minimal code (20-30 lines)
- ✅ Built-in search, swipe actions, selection handling
- ✅ Automatic updates via Combine
- ✅ Consistent UI and behavior

### Option 2: Custom Implementation

If you need a custom UI, you can build your own using the manager:

### Step 1: Create the View Controller

```swift
import UIKit
import Combine
import FinClipChatKit

class ConversationListViewController: UIViewController {
    private let conversationManager: ChatKitConversationManager
    private var tableView: UITableView!
    private var records: [ConversationRecord] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(conversationManager: ChatKitConversationManager) {
        self.conversationManager = conversationManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        observeConversations()
    }
    
    private func setupUI() {
        title = "Conversations"
        view.backgroundColor = .systemBackground
        
        // Add "New Chat" button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createNewChat)
        )
        
        // Setup table view
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
    }
    
    private func observeConversations() {
        conversationManager.recordsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                self?.records = records
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    @objc private func createNewChat() {
        Task { @MainActor in
            let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
            
            do {
                let (record, conversation) = try await conversationManager.createConversation(
                    agentId: agentId,
                    title: nil,
                    agentName: "My Agent",
                    deviceId: deviceId
                )
                
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

### Step 2: Implement Table View

```swift
extension ConversationListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ConversationCell
        let record = records[indexPath.row]
        cell.configure(with: record)
        return cell
    }
}

extension ConversationListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let record = records[indexPath.row]
        guard let conversation = conversationManager.conversation(for: record.id) else {
            return
        }
        
        let chatVC = ChatKitConversationViewController(
            record: record,
            conversation: conversation,
            coordinator: coordinator,
            configuration: .default
        )
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        if editingStyle == .delete {
            let record = records[indexPath.row]
            conversationManager.deleteConversation(sessionId: record.id)
        }
    }
}
```

### Step 3: Create a Custom Cell

```swift
class ConversationCell: UITableViewCell {
    func configure(with record: ConversationRecord) {
        var config = defaultContentConfiguration()
        
        config.text = record.title
        config.secondaryText = record.lastMessagePreview ?? "No messages yet"
        
        // Show relative time ("5 min ago")
        config.secondaryTextProperties.color = .secondaryLabel
        
        contentConfiguration = config
        
        // Add timestamp as accessory
        let label = UILabel()
        label.text = record.lastUpdatedDescription
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        accessoryView = label
    }
}
```

### Result

You now have a full-featured conversation list with:
- ✅ All conversations sorted by recency
- ✅ Auto-updating when messages arrive
- ✅ Swipe-to-delete
- ✅ Tap to resume conversation
- ✅ "Add" button for new chats

---

## API Levels and Provider Customization

### Understanding API Levels

ChatKit provides multiple API levels:

#### High-Level APIs (Recommended)
- `ChatKitCoordinator` - Runtime lifecycle
- `ChatKitConversationViewController` - Ready-made chat UI
- `ChatKitConversationListViewController` - Ready-made list UI
- Minimal code, maximum productivity

**See**: [API Levels Guide](../api-levels.md#high-level-apis-recommended)

#### Low-Level APIs (Advanced)
- Direct runtime access
- Manual UI binding
- Custom implementations
- More code, more control

**See**: [API Levels Guide](../api-levels.md#low-level-apis-advanced)

### Provider Customization

Customize framework behavior without modifying framework code:

#### Context Providers
Attach contextual information (location, calendar events) to messages:

```swift
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

// Register in configuration
var config = ChatKitConversationConfiguration.default
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [ConvoUIContextProviderBridge(provider: LocationContextProvider())]
    }
}
```

#### ASR Providers
Custom Automatic Speech Recognition for voice input:

```objc
@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // Your ASR implementation
    completion(transcribedText, nil);
}

@end
```

#### Title Generation Providers
Custom conversation title generation:

```swift
class CustomTitleProvider: ConversationTitleProvider {
    func shouldGenerateTitle(sessionId: UUID, messageCount: Int, currentTitle: String?) async -> Bool {
        return messageCount >= 3 && currentTitle == nil
    }
    
    func generateTitle(messages: [NeuronMessage]) async throws -> String? {
        // Your title generation logic (e.g., LLM call)
        return try await callLLMForTitle(messages: messages)
    }
}

// Register when creating manager
let manager = ChatKitConversationManager(titleProvider: CustomTitleProvider())
```

**See**: [API Levels Guide](../api-levels.md#provider-mechanism) for complete details.

---

## Complete Examples

Explore the working examples in this repository:

### Simple (Swift)
**Location**: `demo-apps/iOS/Simple/`

**What it demonstrates**:
- High-level APIs (`ChatKitCoordinator`, `ChatKitConversationViewController`)
- Drawer-based navigation pattern
- Component embedding
- Standard build tooling

**Run it**:
```bash
cd demo-apps/iOS/Simple
make run
```

**See**: [Simple README](../../../demo-apps/iOS/Simple/README.md)

### SimpleObjC (Objective-C)
**Location**: `demo-apps/iOS/SimpleObjC/`

**What it demonstrates**:
- Objective-C high-level APIs
- Navigation-based flow
- Remote dependency usage

**Run it**:
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**See**: [SimpleObjC README](../../../demo-apps/iOS/SimpleObjC/README.md)

### Additional Examples

For more advanced patterns and use cases, explore the complete working examples:

- **Simple Demo** (`demo-apps/iOS/Simple/`) - Swift high-level APIs
- **SimpleObjC Demo** (`demo-apps/iOS/SimpleObjC/`) - Objective-C high-level APIs

Both examples demonstrate:
- High-level API usage
- Component embedding patterns
- Provider customization
- Standard build tooling

**Note:** These examples demonstrate high-level APIs with minimal code - perfect for learning!

---

## Best Practices

### ✅ DO

1. **Initialize runtime once at app launch**
   ```swift
   // In AppDelegate or SceneDelegate
   let coordinator = ChatKitCoordinator(config: config)
   ```

2. **Create conversations when user requests them**
   ```swift
   // When user taps "New Chat"
   let (record, conversation) = try await coordinator.startConversation(...)
   let chatVC = ChatKitConversationViewController(...)
   ```

3. **Use ChatKitConversationManager for multi-session apps**
   ```swift
   let manager = ChatKitConversationManager()
   manager.attach(runtime: coordinator.runtime)
   ```

4. **Observe updates reactively**
   ```swift
   manager.recordsPublisher
       .sink { records in /* update UI */ }
       .store(in: &cancellables)
   ```

5. **Use high-level components**
   ```swift
   // Ready-made components handle lifecycle automatically
   let chatVC = ChatKitConversationViewController(...)
   let listVC = ChatKitConversationListViewController(...)
   ```

### ❌ DON'T

1. **Don't create conversations at app launch**
   ```swift
   // ❌ BAD: Creates conversation too early
   let coordinator = ChatKitCoordinator(config: config)
   let conversation = try await coordinator.startConversation(...) // Too soon!
   ```

2. **Don't create multiple coordinators**
   ```swift
   // ❌ BAD: Creates multiple runtimes, loses state
   func createChat() {
       let coordinator = ChatKitCoordinator(config: config) // Don't do this!
   }
   ```

3. **Don't forget to store coordinator**
   ```swift
   // ❌ BAD: Coordinator gets deallocated immediately
   func setup() {
       let coordinator = ChatKitCoordinator(config: config)
       // Oops, coordinator is released when function returns
   }
   
   // ✅ GOOD: Store at class/app level
   class AppCoordinator {
       private let chatCoordinator: ChatKitCoordinator
   }
   ```

4. **Don't block the main thread**
   ```swift
   // ❌ BAD: Persistence is async, don't wait for it
   let (record, conversation) = manager.createConversation(...)
   waitForPersistence() // Don't do this
   
   // ✅ GOOD: Persistence happens automatically in background
   let (record, conversation) = manager.createConversation(...)
   // Use conversation immediately, persistence happens async
   ```

5. **Don't use low-level APIs unless necessary**
   ```swift
   // ❌ BAD: Unnecessary complexity
   let hosting = ChatHostingController()
   let adapter = ChatKitAdapter(chatView: hosting.chatView)
   conversation.bindUI(adapter) // Too verbose!
   
   // ✅ GOOD: Use high-level component
   let chatVC = ChatKitConversationViewController(...) // Simple!
   ```

---

## Troubleshooting

### "ChatKitCoordinator not found"

**Solution**: Ensure you're using ChatKit v0.7.4 or later:
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
```

### Conversations not persisting

**Solution**: Ensure you're using `.persistent` storage:
```swift
let config = NeuronKitConfig.default(serverURL: url)
    .withUserId(userId)
// Persistent storage is the default
```

### Messages not updating in UI

**Solution**: Make sure you're observing the conversation or manager:
```swift
// Option 1: Observe individual conversation
conversation.messagesPublisher
    .sink { messages in /* update UI */ }
    .store(in: &cancellables)

// Option 2: Observe all conversations via manager
manager.recordsPublisher
    .sink { records in /* update list */ }
    .store(in: &cancellables)
```

---

## API Reference

### ChatKitCoordinator

```swift
public final class ChatKitCoordinator {
    public init(config: NeuronKitConfig)
    public var runtime: NeuronRuntime { get }
}
```

### ChatKitConversationManager

```swift
@MainActor
public final class ChatKitConversationManager {
    public init()
    
    public func attach(runtime: NeuronRuntime)
    public func detach()
    
    public func createConversation(
        agentId: UUID,
        title: String? = nil,
        deviceId: String? = nil
    ) -> (record: ConversationRecord, conversation: Conversation)?
    
    public func conversation(for sessionId: UUID) -> Conversation?
    public func record(for sessionId: UUID) -> ConversationRecord?
    
    public func deleteConversation(sessionId: UUID)
    public func updateTitle(for sessionId: UUID, title: String)
    public func allConversations() -> [ConversationRecord]
    
    public var recordsPublisher: AnyPublisher<[ConversationRecord], Never> { get }
}
```

### ConversationRecord

```swift
public struct ConversationRecord: Identifiable, Equatable {
    public let id: UUID
    public let agentId: UUID
    public var title: String
    public var lastMessagePreview: String?
    public var lastUpdatedAt: Date
    public var lastUpdatedDescription: String { get }
}
```

### NeuronRuntime

```swift
public final class NeuronRuntime {
    public func openConversation(sessionId: UUID, agentId: UUID) -> Conversation
    public func resumeConversation(sessionId: UUID, agentId: UUID) -> Conversation
    public var conversationRepository: ConversationRepository? { get }
}
```

### Conversation

```swift
public final class Conversation {
    public let sessionId: UUID
    public var messagesPublisher: AnyPublisher<[Message], Never> { get }
    public func sendMessage(_ content: String) async throws
    public func bindUI(_ adapter: ConvoUIAdapter)
    public func unbindUI()
    public func close()
}
```

---

## Next Steps

1. **Build your first app** - Start with Part 1
2. **Add conversation management** - Follow Part 2
3. **Implement history UI** - Complete Part 3
4. **Explore demos** - Study Simple and SimpleObjC examples
5. **Customize** - See `docs/how-to/customize-ui.md`

---

## Support

- **Examples**: `demo-apps/iOS/`
- **API Docs**: `docs/reference/`
- **Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

Happy coding! 🚀
