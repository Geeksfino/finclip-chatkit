# Swift 开发者指南

全面指南，从初学者到专家，教您使用 ChatKit SDK 在 Swift 中构建对话式 AI 应用。

> 🚀 **刚接触 ChatKit？** 从 [Swift 快速开始](../getting-started.zh.md#swift-快速开始) 开始，5 分钟即可完成设置。
> 
> 📘 **Objective-C 开发者？** 参见 [Objective-C 开发者指南](./objective-c-guide.zh.md)。

---

## 目录

1. [第一部分：入门 - 您的第一个 AI 聊天应用](#第一部分入门)
2. [第二部分：管理多个会话](#第二部分管理多个会话)
3. [第三部分：构建会话列表 UI](#第三部分构建会话列表-ui)
4. [API 层级和提供器自定义](#api-层级和提供器自定义)
5. [完整示例](#完整示例)

---

## 第一部分：入门

在 10 分钟内构建您的第一个 AI 聊天应用。

### 前置条件

- **Xcode 15.0+**
- **iOS 16.0+** 部署目标
- **Swift 5.9+**

### 步骤 1：添加 ChatKit 依赖

在项目根目录创建 `Package.swift`：

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

### 步骤 2：初始化运行时（还不是会话！）

关键模式：**尽早初始化运行时，在用户采取行动时创建会话**。

```swift
import UIKit
import FinClipChatKit

class AppCoordinator {
    // 在应用级别存储协调器 - 它管理运行时生命周期
    private let chatCoordinator: ChatKitCoordinator
    
    init() {
        // 1. 创建配置
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-agent-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        
        // 2. 初始化 ChatKitCoordinator（创建一次运行时）
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // 注意：我们还不创建会话！
        // 用户还没有采取行动。
    }
    
    // 稍后，当用户点击"新聊天"按钮时：
    func userRequestedNewChat(agentId: UUID) async {
        // 3. 现在我们创建会话
        do {
            let (record, conversation) = try await chatCoordinator.startConversation(
                agentId: agentId,
                title: nil,
                agentName: "My Agent"
            )
            
            // 4. 使用高级组件显示现成的聊天 UI
            let chatVC = ChatKitConversationViewController(
                record: record,
                conversation: conversation,
                coordinator: chatCoordinator,
                configuration: .default
            )
            navigationController?.pushViewController(chatVC, animated: true)
        } catch {
            print("创建会话失败: \(error)")
        }
    }
}
```

### 步骤 3：理解流程

**重要提示**：不要混淆这两个步骤：

1. **运行时初始化**（在应用启动时执行一次）
   - 创建 `ChatKitCoordinator`
   - 建立到服务器的连接
   - 加载任何持久化状态

2. **会话创建**（当用户采取行动时执行）
   - 用户点击"新聊天"或从历史记录中选择
   - 创建 `Conversation` 实例
   - 打开聊天 UI

### 步骤 4：完整示例

这是一个最小的可工作应用：

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
        // 初始化运行时
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // 显示带有空状态的主 UI
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
        
        // 添加"新聊天"按钮
        let button = UIButton(type: .system)
        button.setTitle("开始新聊天", for: .normal)
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
            // 现在创建会话（用户请求了）
            let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
            
            do {
                let (record, conversation) = try await coordinator.startConversation(
                    agentId: agentId,
                    title: nil,
                    agentName: "My Agent"
                )
                
                // 使用高级组件显示现成的聊天 UI
                let chatVC = ChatKitConversationViewController(
                    record: record,
                    conversation: conversation,
                    coordinator: coordinator,
                    configuration: .default
                )
                navigationController?.pushViewController(chatVC, animated: true)
            } catch {
                print("创建会话失败: \(error)")
            }
        }
    }
}
```

### 关键概念

#### ChatKitCoordinator
管理 `NeuronRuntime` 生命周期的**推荐方式**。它确保：
- 运行时只创建一次并持久存在
- 安全处理配置更改
- 释放时自动清理

**为什么使用它？** 直接创建新的 `NeuronRuntime` 会销毁之前的运行时，丢失所有会话状态。`ChatKitCoordinator` 可以防止这种情况。

#### 运行时
核心编排层（通过 `coordinator.runtime` 访问），它：
- 连接到您的 AI 代理服务器
- 管理会话状态
- 处理消息路由
- 提供会话持久化

**注意**：您通常不需要直接访问运行时。而是使用 `ChatKitCoordinator` 的方法。

#### 会话
代表单个聊天会话。每个会话具有：
- 唯一的 `sessionId`（UUID）
- 关联的 `agentId`
- 消息历史
- UI 绑定能力

**何时创建？** 当用户明确请求时（点击按钮、从列表中选择），而不是在应用初始化期间。

**如何显示？** 使用 `ChatKitConversationViewController` - 一个自动处理所有 UI 的现成组件。

---

## 第二部分：管理多个会话

学习跟踪和在多个会话之间切换。

### 挑战

实际应用需要：
- 多个同时进行的会话
- 从历史记录恢复会话
- 跟踪会话元数据（标题、最后一条消息、时间戳）
- 响应式 UI 更新

### 解决方案：ChatKitConversationManager

ChatKit 提供了可选的 `ChatKitConversationManager` 来为您处理所有这些！

### 步骤 1：设置管理器

```swift
import FinClipChatKit

class AppCoordinator {
    private let chatCoordinator: ChatKitCoordinator
    private let conversationManager: ChatKitConversationManager
    
    init() {
        // 1. 初始化运行时
        let config = NeuronKitConfig(
            serverURL: URL(string: "https://your-server.com")!,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            userId: "user-123",
            storage: .persistent
        )
        chatCoordinator = ChatKitCoordinator(config: config)
        
        // 2. 初始化会话管理器
        conversationManager = ChatKitConversationManager()
        conversationManager.attach(runtime: chatCoordinator.runtime)
        
        // 管理器自动加载持久化的会话
    }
}
```

### 步骤 2：创建会话

```swift
func createNewConversation(agentId: UUID, title: String? = nil) async {
    do {
        let (record, conversation) = try await conversationManager.createConversation(
            agentId: agentId,
            title: title,
            agentName: "My Agent",
            deviceId: deviceId
        )
        
        // record: 元数据（id、标题、最后一条消息等）
        // conversation: 实际的 Conversation 实例
        
        // 显示现成的聊天 UI
        let chatVC = ChatKitConversationViewController(
            record: record,
            conversation: conversation,
            coordinator: chatCoordinator,
            configuration: .default
        )
        navigationController?.pushViewController(chatVC, animated: true)
    } catch {
        print("创建会话失败: \(error)")
    }
}
```

### 步骤 3：恢复现有会话

```swift
func resumeConversation(sessionId: UUID) {
    guard let conversation = conversationManager.conversation(for: sessionId),
          let record = conversationManager.record(for: sessionId) else {
        print("会话未找到")
        return
    }
    
    // 显示现成的聊天 UI
    let chatVC = ChatKitConversationViewController(
        record: record,
        conversation: conversation,
        coordinator: chatCoordinator,
        configuration: .default
    )
    navigationController?.pushViewController(chatVC, animated: true)
}
```

### 步骤 4：观察会话更新

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
                // 按 lastUpdatedAt 排序（最近的在前）
                self?.updateConversationList(records)
            }
            .store(in: &cancellables)
    }
    
    private func updateConversationList(_ records: [ConversationRecord]) {
        // 使用会话列表更新 UI
        for record in records {
            print("会话: \(record.id)")
            print("标题: \(record.title)")
            print("最后一条消息: \(record.lastMessagePreview ?? "无")")
            print("更新时间: \(record.lastUpdatedDescription)") // "5 分钟前"
        }
    }
}
```

### 步骤 5：删除会话

```swift
func deleteConversation(sessionId: UUID) {
    conversationManager.deleteConversation(sessionId: sessionId)
    // 自动从内存和持久化存储中移除
    // recordsPublisher 将发出更新后的列表
}
```

### 您获得的功能

`ChatKitConversationManager` 自动处理：

- ✅ **会话创建** - 创建并跟踪新会话
- ✅ **持久化** - 自动保存到 convstore
- ✅ **消息观察** - 监视新消息
- ✅ **记录更新** - 更新 lastMessage、lastUpdatedAt
- ✅ **自动标题生成** - 使用第一条用户消息作为标题
- ✅ **响应式更新** - 通过 Combine 发布更改
- ✅ **内存管理** - 删除时正确解绑 UI

---

## 第三部分：构建会话列表 UI

现在让我们构建一个会话历史视图。ChatKit 提供了一个现成的组件：`ChatKitConversationListViewController`。

### 选项 1：使用现成组件（推荐）

最简单的方法是使用 `ChatKitConversationListViewController`：

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
        
        // 创建现成的会话列表
        var config = ChatKitConversationListConfiguration.default
        config.headerTitle = "会话"
        config.showSearchBar = true
        config.showNewButton = true
        config.enableSwipeToDelete = true
        
        let listVC = ChatKitConversationListViewController(
            coordinator: coordinator,
            configuration: config
        )
        listVC.delegate = self
        
        // 嵌入导航控制器
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
        // 用户选择了一个会话 - 显示聊天
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
        // 用户点击了"新建"按钮 - 创建会话
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

**优点**：
- ✅ 代码量最少（20-30 行）
- ✅ 内置搜索、滑动操作、选择处理
- ✅ 通过 Combine 自动更新
- ✅ 一致的 UI 和行为

### 选项 2：自定义实现

如果您需要自定义 UI，可以使用管理器构建自己的：

### 步骤 1：创建视图控制器

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
        title = "会话"
        view.backgroundColor = .systemBackground
        
        // 添加"新聊天"按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(createNewChat)
        )
        
        // 设置表格视图
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
                print("创建会话失败: \(error)")
            }
        }
    }
}
```

### 步骤 2：实现表格视图

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

### 步骤 3：创建自定义单元格

```swift
class ConversationCell: UITableViewCell {
    func configure(with record: ConversationRecord) {
        var config = defaultContentConfiguration()
        
        config.text = record.title
        config.secondaryText = record.lastMessagePreview ?? "还没有消息"
        
        // 显示相对时间（"5 分钟前"）
        config.secondaryTextProperties.color = .secondaryLabel
        
        contentConfiguration = config
        
        // 添加时间戳作为附件
        let label = UILabel()
        label.text = record.lastUpdatedDescription
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        accessoryView = label
    }
}
```

### 结果

您现在拥有一个功能齐全的会话列表，包括：
- ✅ 按最近时间排序的所有会话
- ✅ 消息到达时自动更新
- ✅ 滑动删除
- ✅ 点击恢复会话
- ✅ "添加"按钮用于新聊天

---

## API 层级和提供器自定义

### 理解 API 层级

ChatKit 提供多个 API 层级：

#### 高级 API（推荐）
- `ChatKitCoordinator` - 运行时生命周期
- `ChatKitConversationViewController` - 现成的聊天 UI
- `ChatKitConversationListViewController` - 现成的列表 UI
- 代码最少，生产力最高

**参见**：[API 层级指南](../api-levels.zh.md#高级-api推荐)

#### 低级 API（高级）
- 直接运行时访问
- 手动 UI 绑定
- 自定义实现
- 更多代码，更多控制

**参见**：[API 层级指南](../api-levels.zh.md#低级-api高级)

### 提供器自定义

无需修改框架代码即可自定义框架行为：

#### 上下文提供器
将上下文信息（位置、日历事件）附加到消息：

```swift
class LocationContextProvider: ConvoUIContextProvider {
    func provideContext(completion: @escaping (ConvoUIContext?) -> Void) {
        // 您的位置逻辑
        let context = ConvoUIContext(
            title: "当前位置",
            content: "纬度: 37.7749, 经度: -122.4194"
        )
        completion(context)
    }
}

// 在配置中注册
var config = ChatKitConversationConfiguration.default
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [ConvoUIContextProviderBridge(provider: LocationContextProvider())]
    }
}
```

#### ASR 提供器
自定义语音输入的自动语音识别：

```objc
@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 您的 ASR 实现
    completion(transcribedText, nil);
}

@end
```

#### 标题生成提供器
自定义会话标题生成：

```swift
class CustomTitleProvider: ConversationTitleProvider {
    func shouldGenerateTitle(sessionId: UUID, messageCount: Int, currentTitle: String?) async -> Bool {
        return messageCount >= 3 && currentTitle == nil
    }
    
    func generateTitle(messages: [NeuronMessage]) async throws -> String? {
        // 您的标题生成逻辑（例如，LLM 调用）
        return try await callLLMForTitle(messages: messages)
    }
}

// 创建管理器时注册
let manager = ChatKitConversationManager(titleProvider: CustomTitleProvider())
```

**参见**：[API 层级指南](../api-levels.zh.md#提供器机制) 获取完整详情。

---

## 完整示例

探索此仓库中的工作示例：

### Simple（Swift）
**位置**：`demo-apps/iOS/Simple/`

**演示内容**：
- 高级 API（`ChatKitCoordinator`、`ChatKitConversationViewController`）
- 抽屉式导航模式
- 组件嵌入
- 标准构建工具

**运行方法**：
```bash
cd demo-apps/iOS/Simple
make run
```

**参见**：[Simple README](../../../demo-apps/iOS/Simple/README.md)

### SimpleObjC（Objective-C）
**位置**：`demo-apps/iOS/SimpleObjC/`

**演示内容**：
- Objective-C 高级 API
- 基于导航的流程
- 远程依赖使用

**运行方法**：
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**参见**：[SimpleObjC README](../../../demo-apps/iOS/SimpleObjC/README.md)

### 其他示例

有关更高级的模式和用例，探索完整的工作示例：

- **Simple 演示**（`demo-apps/iOS/Simple/`）- Swift 高级 API
- **SimpleObjC 演示**（`demo-apps/iOS/SimpleObjC/`）- Objective-C 高级 API

两个示例都演示了：
- 高级 API 使用
- 组件嵌入模式
- 提供器自定义
- 标准构建工具

**注意：** 这些示例展示了使用最少代码的高级 API - 非常适合学习！

---

## 最佳实践

### ✅ 应该做的

1. **在应用启动时初始化运行时一次**
   ```swift
   // 在 AppDelegate 或 SceneDelegate 中
   let coordinator = ChatKitCoordinator(config: config)
   ```

2. **在用户请求时创建会话**
   ```swift
   // 当用户点击"新聊天"时
   let (record, conversation) = try await coordinator.startConversation(...)
   let chatVC = ChatKitConversationViewController(...)
   ```

3. **对多会话应用使用 ChatKitConversationManager**
   ```swift
   let manager = ChatKitConversationManager()
   manager.attach(runtime: coordinator.runtime)
   ```

4. **响应式观察更新**
   ```swift
   manager.recordsPublisher
       .sink { records in /* 更新 UI */ }
       .store(in: &cancellables)
   ```

5. **使用高级组件**
   ```swift
   // 现成的组件自动处理生命周期
   let chatVC = ChatKitConversationViewController(...)
   let listVC = ChatKitConversationListViewController(...)
   ```

### ❌ 不应该做的

1. **不要在应用启动时创建会话**
   ```swift
   // ❌ 错误：过早创建会话
   let coordinator = ChatKitCoordinator(config: config)
   let conversation = try await coordinator.startConversation(...) // 太早了！
   ```

2. **不要创建多个协调器**
   ```swift
   // ❌ 错误：创建多个运行时，丢失状态
   func createChat() {
       let coordinator = ChatKitCoordinator(config: config) // 不要这样做！
   }
   ```

3. **不要忘记存储协调器**
   ```swift
   // ❌ 错误：协调器立即被释放
   func setup() {
       let coordinator = ChatKitCoordinator(config: config)
       // 糟糕，协调器在函数返回时被释放
   }
   
   // ✅ 正确：在类/应用级别存储
   class AppCoordinator {
       private let chatCoordinator: ChatKitCoordinator
   }
   ```

4. **不要阻塞主线程**
   ```swift
   // ❌ 错误：持久化是异步的，不要等待它
   let (record, conversation) = manager.createConversation(...)
   waitForPersistence() // 不要这样做
   
   // ✅ 正确：持久化在后台自动发生
   let (record, conversation) = manager.createConversation(...)
   // 立即使用会话，持久化异步发生
   ```

5. **不要使用低级 API 除非必要**
   ```swift
   // ❌ 错误：不必要的复杂性
   let hosting = ChatHostingController()
   let adapter = ChatKitAdapter(chatView: hosting.chatView)
   conversation.bindUI(adapter) // 太冗长！
   
   // ✅ 正确：使用高级组件
   let chatVC = ChatKitConversationViewController(...) // 简单！
   ```

---

## 发送带上下文的消息

ChatKit 提供了使用 `ChatKitContextItemFactory` 以编程方式将上下文附加到消息的统一方法。该工厂从简单的元数据字典创建 `ConversationContextItem` 实例，确保所有上下文都经过正确格式化并发送给代理。

### 使用 ChatKitContextItemFactory (Swift)

**基本示例:**

```swift
import FinClipChatKit

// 创建上下文元数据
let context: [String: Any] = [
    "type": "strategy",
    "strategyId": "123",
    "strategyTitle": "增长策略"
]

// 使用工厂创建上下文项
let contextItem = ChatKitContextItemFactory.metadata(context, type: "strategy")

// 发送带上下文的消息
try await conversation.sendMessage(
    "告诉我这个策略的情况",
    contextItems: [contextItem]
)
```

**带显示名称:**

```swift
let contextItem = ChatKitContextItemFactory.metadata(
    ["strategyId": "123", "strategyTitle": "增长"],
    type: "strategy",
    displayName: "增长策略"
)

try await conversation.sendMessage(
    "分析这个策略",
    contextItems: [contextItem]
)
```

**多个上下文项:**

```swift
// 创建多个上下文项
let strategyContext = ChatKitContextItemFactory.metadata(
    ["strategyId": "123", "strategyTitle": "增长"],
    type: "strategy"
)
let userContext = ChatKitContextItemFactory.metadata(
    ["userId": "456", "userRole": "premium"],
    type: "user"
)

try await conversation.sendMessage(
    "为我的账户分析这个策略",
    contextItems: [strategyContext, userContext]
)
```

**使用多个项的便利方法:**

```swift
let contexts: [[String: Any]] = [
    ["strategyId": "123", "strategyTitle": "增长"],
    ["userId": "456", "userRole": "premium"]
]

let contextItems = ChatKitContextItemFactory.metadataItems(contexts, type: "metadata")
try await conversation.sendMessage("分析这些", contextItems: contextItems)
```

### 何时使用程序化上下文 vs. UI 上下文提供器

- **使用 `ChatKitContextItemFactory`** 当:
  - 您需要以编程方式发送上下文（例如，从按钮点击、导航事件）
  - 上下文来自您的应用数据模型（例如，选定的策略、用户配置文件）
  - 您想在没有用户交互的情况下附加上下文

- **使用上下文提供器** 当:
  - 上下文需要用户输入（例如，位置选择器、日期选择）
  - 上下文应通过 UI 动态收集
  - 上下文需要由用户刷新或更新

### 实际示例

以下是在用户点击策略卡片时如何使用程序化上下文的示例:

```swift
func strategyCardDidTap(_ strategy: Strategy) {
    let message = "告诉我这个策略的情况"
    let context: [String: Any] = [
        "type": "strategy",
        "strategyId": strategy.id,
        "strategyTitle": strategy.title
    ]
    
    Task { @MainActor in
        do {
            let (record, conversation) = try await coordinator.startConversation(
                agentId: agentId,
                title: nil,
                agentName: "我的代理"
            )
            
            // 创建上下文项并发送初始消息
            let contextItem = ChatKitContextItemFactory.metadata(context, type: "strategy")
            try await conversation.sendMessage(message, contextItems: [contextItem])
            
            // 显示聊天 UI
            let chatVC = ChatKitConversationViewController(
                record: record,
                conversation: conversation,
                coordinator: coordinator,
                configuration: .default
            )
            navigationController?.pushViewController(chatVC, animated: true)
        } catch {
            print("启动对话失败: \(error)")
        }
    }
}
```

---

## 故障排除

### "找不到 ChatKitCoordinator"

**解决方案**：确保您使用的是 ChatKit v0.7.4 或更高版本：
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
```

### 会话未持久化

**解决方案**：确保您使用的是 `.persistent` 存储：
```swift
let config = NeuronKitConfig.default(serverURL: url)
    .withUserId(userId)
// 默认使用持久化存储
```

### UI 中消息未更新

**解决方案**：确保您正在观察会话或管理器：
```swift
// 选项 1：观察单个会话
conversation.messagesPublisher
    .sink { messages in /* 更新 UI */ }
    .store(in: &cancellables)

// 选项 2：通过管理器观察所有会话
manager.recordsPublisher
    .sink { records in /* 更新列表 */ }
    .store(in: &cancellables)
```

---

## API 参考

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

## 下一步

1. **构建您的第一个应用** - 从第一部分开始
2. **添加会话管理** - 遵循第二部分
3. **实现历史 UI** - 完成第三部分
4. **探索演示** - 研究 Simple 和 SimpleObjC 示例
5. **自定义** - 参见 `docs/how-to/customize-ui.zh.md`

---

## 支持

- **示例**：`demo-apps/iOS/`
- **API 文档**：`docs/reference/`
- **问题**：[GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

祝编码愉快！ 🚀
