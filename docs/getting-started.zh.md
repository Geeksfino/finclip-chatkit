# ChatKit 入门指南

欢迎使用 ChatKit！本指南提供特定语言的快速开始，帮助您在几分钟内启动并运行。

> 🚀 **想要最小化代码？** 参见[快速开始指南](./quick-start.zh.md)获取骨架模板（5 分钟）。
> 
> 📚 **寻找全面指南？**
> - **Swift**: [Swift 开发者指南](./guides/developer-guide.zh.md)
> - **Objective-C**: [Objective-C 开发者指南](./guides/objective-c-guide.zh.md)

---

## 选择您的语言

- **[Swift 快速开始](#swift-快速开始)** - Swift 开发者从这里开始
- **[Objective-C 快速开始](#objective-c-快速开始)** - Objective-C 开发者从这里开始

---

## Swift 快速开始

### 前提条件

- **Xcode 15.0+**
- **iOS 16.0+** 部署目标
- **Swift 5.9+**

### 1. 添加 ChatKit 依赖

创建或更新您的 `Package.swift`：

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

### 2. 初始化协调器（只做一次！）

**重要**：在应用启动时初始化协调器，但还不要创建会话。

```swift
import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // 1. 创建配置
        let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
            .withUserId("demo-user")
        
        // 2. 初始化 ChatKitCoordinator（一次性创建运行时）
        let coordinator = ChatKitCoordinator(config: config)
        
        // 3. 显示主 UI（空状态或会话列表）
        let mainVC = MainViewController(coordinator: coordinator)
        window.rootViewController = UINavigationController(rootViewController: mainVC)
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
```

### 3. 创建会话并显示聊天 UI

**不要在应用启动时创建会话！** 等待用户操作：

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
        
        // 显示"新聊天"按钮
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
            // 现在创建会话（用户请求的）
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

### 就是这样！

您现在拥有一个可工作的 AI 聊天应用，具有：
- ✅ 持久化会话存储
- ✅ 安全的运行时生命周期管理
- ✅ 功能完整的聊天 UI（现成组件）
- ✅ 消息历史
- ✅ 最小化代码（20-30 行）

---

## 关键概念

### 两步模式

理解这些步骤之间的区别至关重要：

#### 步骤 1：协调器初始化（一次，在应用启动时）
```swift
// 在 AppDelegate/SceneDelegate 中执行此操作
let config = NeuronKitConfig.default(serverURL: serverURL).withUserId("user-123")
let coordinator = ChatKitCoordinator(config: config)
```

**发生什么：**
- 创建运行时实例
- 建立服务器连接
- 加载持久化状态
- 准备基础设施

**何时：** 应用启动时，每个应用生命周期一次

#### 步骤 2：会话创建（多次，用户发起）
```swift
// 当用户点击"新聊天"或从历史中选择时执行此操作
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)
```

**发生什么：**
- 创建会话
- 与 AI 代理关联
- 打开聊天流
- 返回记录和会话

**何时：** 用户请求时（按钮点击、从列表选择）

### ChatKitCoordinator

管理 `NeuronRuntime` 生命周期的**推荐方式**。

**为什么使用它？** 创建新运行时会销毁旧的，丢失所有会话状态。`ChatKitCoordinator` 确保运行时在应用中持久存在。

**在哪里存储它？** 在应用级别（AppDelegate、SceneDelegate 或根协调器）。

### 常见陷阱

```swift
// ❌ 错误：过早创建会话
func application(...) -> Bool {
    let coordinator = ChatKitCoordinator(config: config)
    let conversation = try await coordinator.startConversation(...) // 太早了！
    return true
}

// ✅ 正确：初始化协调器，稍后创建会话
func scene(...) {
    let coordinator = ChatKitCoordinator(config: config) // 只有协调器
    // 显示空状态或会话列表
}

// 稍后，当用户点击按钮时：
@objc func newChat() {
    let (record, conversation) = try await coordinator.startConversation(...) // 现在！
    let chatVC = ChatKitConversationViewController(...) // 显示 UI
}
```

---

## Objective-C 快速开始

### 前提条件

- **Xcode 15.0+**
- **iOS 16.0+** 部署目标
- **Objective-C** 项目

### 1. 添加 ChatKit 依赖

添加到您的 `Package.swift` 或在 Xcode 中配置：

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
]
```

### 2. 初始化协调器（只做一次！）

**重要**：在应用启动时初始化协调器，但还不要创建会话。

```objc
#import "SceneDelegate.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session 
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // 1. 创建配置
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    
    // 2. 初始化 ChatKitCoordinator（一次性创建运行时）
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    
    // 3. 显示主 UI（空状态或会话列表）
    MainViewController *mainVC = [[MainViewController alloc] initWithCoordinator:coordinator];
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:mainVC];
    [window makeKeyAndVisible];
    
    self.window = window;
}

@end
```

### 3. 创建会话并显示聊天 UI

**不要在应用启动时创建会话！** 等待用户操作：

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
    
    // 显示"新聊天"按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"开始新聊天" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(startNewChat) forControlEvents:UIControlEventTouchUpInside];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.view addSubview:button];
    [NSLayoutConstraint activateConstraints:@[
        [button.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [button.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)startNewChat {
    // 现在创建会话（用户请求的）
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            NSLog(@"创建会话失败: %@", error);
            return;
        }
        
        // 使用高级组件显示现成的聊天 UI
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

### 就是这样！

您现在拥有一个可工作的 Objective-C AI 聊天应用，具有：
- ✅ 持久化会话存储
- ✅ 安全的运行时生命周期管理
- ✅ 功能完整的聊天 UI（现成组件）
- ✅ 消息历史
- ✅ 最小化代码（30-40 行）

---

## 关键概念（Objective-C）

### 两步模式

理解这些步骤之间的区别至关重要：

#### 步骤 1：协调器初始化（一次，在应用启动时）
```objc
// 在 AppDelegate/SceneDelegate 中执行此操作
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent;
CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

**发生什么：**
- 创建运行时实例
- 建立服务器连接
- 加载持久化状态
- 准备基础设施

**何时：** 应用启动时，每个应用生命周期一次

#### 步骤 2：会话创建（多次，用户发起）
```objc
// 当用户点击"新聊天"或从历史中选择时执行此操作
[self.coordinator startConversationWithAgentId:agentId
                                          title:nil
                                      agentName:@"My Agent"
                                     completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    // 使用记录和会话
}];
```

**发生什么：**
- 创建会话
- 与 AI 代理关联
- 打开聊天流
- 通过完成处理器返回记录和会话

**何时：** 用户请求时（按钮点击、从列表选择）

### CKTChatKitCoordinator

在 Objective-C 中管理运行时生命周期的**推荐方式**。

**为什么使用它？** 创建新运行时会销毁旧的，丢失所有会话状态。`CKTChatKitCoordinator` 确保运行时在应用中持久存在。

**在哪里存储它？** 在应用级别（AppDelegate、SceneDelegate 或根协调器）。

### 常见陷阱

```objc
// ❌ 错误：过早创建会话
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    [coordinator startConversationWithAgentId:agentId ...]; // 太早了！
    return YES;
}

// ✅ 正确：初始化协调器，稍后创建会话
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options {
    self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config]; // 只有协调器
    // 显示空状态或会话列表
}

// 稍后，当用户点击按钮时：
- (void)startNewChat {
    [self.coordinator startConversationWithAgentId:agentId ...]; // 现在！
    // 显示 UI
}
```

---

## 下一步

选择您的学习路径：

### 📖 想要深入学习？

**Swift 开发者：**
→ 阅读 [Swift 开发者指南](./guides/developer-guide.zh.md)了解：
- **第 1 部分**：简单聊天应用（详细演示）
- **第 2 部分**：管理多个会话
- **第 3 部分**：构建会话历史 UI

**Objective-C 开发者：**
→ 阅读 [Objective-C 开发者指南](./guides/objective-c-guide.zh.md)了解：
- 基础用法模式
- 多会话管理
- 会话列表 UI
- 完整的 API 参考

### 🎯 理解 API 层级？

→ 参见 [API 层级指南](./api-levels.zh.md)了解：
- 高级 API 与低级 API
- 何时使用哪个
- 提供者机制

### 🎨 准备好自定义？

→ 参见 [组件嵌入指南](./component-embedding.zh.md)了解：
- 在弹出层、抽屉、标签页中嵌入（Swift 和 Objective-C 示例）
- 自定义容器模式

→ 参见 [自定义 UI 指南](./how-to/customize-ui.zh.md)了解：
- 样式和主题

### 🔧 设置构建？

→ 参见 [构建工具指南](./build-tooling.zh.md)了解：
- Makefile 和 XcodeGen
- 可重现构建

### 🏗️ 理解架构？

→ 查看 [架构概述](./architecture/overview.zh.md)

### 🔧 遇到问题？

→ 访问 [故障排除指南](./troubleshooting.zh.md)

### 🧪 想看示例？

→ 探索示例应用：

**Simple 示例（Swift）：**
```bash
cd demo-apps/iOS/Simple
make run
```

**SimpleObjC 示例（Objective-C）：**
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**注意：** 这些示例展示了使用最小化代码的高级 API - 非常适合学习！

---

## 快速参考

### 最小可行聊天应用

```swift
// 1. 初始化协调器（一次，在应用启动时）
let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
    .withUserId("demo-user")
let coordinator = ChatKitCoordinator(config: config)

// 2. 稍后，当用户请求聊天时：
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)

// 3. 显示现成的聊天 UI
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)
navigationController?.pushViewController(chatVC, animated: true)
```

### 使用会话管理器（多会话应用）

```swift
// 1. 初始化
let coordinator = ChatKitCoordinator(config: config)
let manager = ChatKitConversationManager()
manager.attach(runtime: coordinator.runtime)

// 2. 创建会话
let (record, conversation) = try await manager.createConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent",
    deviceId: deviceId
)

// 3. 显示聊天 UI
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// 4. 观察更新
manager.recordsPublisher
    .sink { records in
        // 使用会话列表更新 UI
    }
    .store(in: &cancellables)
```

---

## 支持

- **全面指南**: [开发者指南](./guides/developer-guide.zh.md)
- **示例**: `demo-apps/iOS/AI-Bank` 和 `demo-apps/iOS/Smart-Gov`
- **问题**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

祝您编码愉快！🚀
