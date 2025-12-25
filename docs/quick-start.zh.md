# 快速开始指南

在不到 5 分钟内启动并运行 ChatKit。本指南提供**最小化骨架代码**来构建您的第一个 AI 聊天应用。

> 📚 **想要详细解释？** 参见[入门指南](./getting-started.zh.md)获取带解释的完整演练。
> 
> 📖 **寻找全面模式？** 参见[Swift 开发者指南](./guides/developer-guide.zh.md)或[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)。
> 
> 📦 **需要安装帮助？** 参见[集成指南](./integration-guide.zh.md)了解包管理器设置。

---

## Swift 快速开始

### 步骤 1：添加依赖

创建或更新您的 `Package.swift`：

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

### 步骤 2：初始化协调器

在您的 `SceneDelegate.swift`（或 `AppDelegate.swift`）中：

```swift
import UIKit
import FinClipChatKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, 
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // 初始化 ChatKitCoordinator（一次性创建运行时）
        let config = NeuronKitConfig.default(serverURL: URL(string: "http://127.0.0.1:3000/agent")!)
            .withUserId("demo-user")
        let coordinator = ChatKitCoordinator(config: config)
        
        // 创建根视图控制器
        let rootVC = MainViewController(coordinator: coordinator)
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
```

### 步骤 3：创建会话并显示聊天

在您的主视图控制器中：

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
        
        // 添加"新聊天"按钮
        let button = UIButton(type: .system)
        button.setTitle("开始聊天", for: .normal)
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
                // 创建会话
                let agentId = UUID(uuidString: "E1E72B3D-845D-4F5D-B6CA-5550F2643E6B")!
                let (record, conversation) = try await coordinator.startConversation(
                    agentId: agentId,
                    title: nil,
                    agentName: "My Agent"
                )
                
                // 使用高级组件显示聊天 UI
                let chatVC = ChatKitConversationViewController(
                    record: record,
                    conversation: conversation,
                    coordinator: coordinator,
                    configuration: .default
                )
                
                let navController = UINavigationController(rootViewController: chatVC)
                present(navController, animated: true)
            } catch {
                print("创建会话失败: \(error)")
            }
        }
    }
}
```

**就是这样！** 您现在拥有一个可工作的 AI 聊天应用，具有：
- ✅ 持久化会话存储
- ✅ 功能完整的聊天 UI
- ✅ 消息历史
- ✅ 安全的运行时生命周期管理

---

## Objective-C 快速开始

### 步骤 1：添加依赖

添加到您的 `Package.swift` 或在 Xcode 中配置：

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
]
```

### 步骤 2：初始化协调器

在您的 `SceneDelegate.m` 中：

```objc
#import "SceneDelegate.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session 
      options:(UISceneConnectionOptions *)connectionOptions {
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    // 初始化 ChatKitCoordinator
    NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
    CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                             userId:@"demo-user"
                                                                           deviceId:nil];
    config.storageMode = CKTStorageModePersistent;
    
    CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
    
    // 创建根视图控制器
    MainViewController *rootVC = [[MainViewController alloc] initWithCoordinator:coordinator];
    window.rootViewController = rootVC;
    [window makeKeyAndVisible];
    
    self.window = window;
}
@end
```

### 步骤 3：创建会话并显示聊天

在您的主视图控制器中：

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
    
    // 添加"新聊天"按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"开始聊天" forState:UIControlStateNormal];
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
            NSLog(@"创建会话失败: %@", error);
            return;
        }
        
        // 使用高级组件显示聊天 UI
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

**就是这样！** 您现在拥有一个可工作的 Objective-C AI 聊天应用。

---

## 下一步

### 深入学习
- **[入门指南](./getting-started.zh.md)** - 带有详细说明的演示（Swift 和 Objective-C）
- **[API 层级指南](./api-levels.zh.md)** - 理解高级 API 与低级 API
- **Swift**: [Swift 开发者指南](./guides/developer-guide.zh.md) - 全面的模式和最佳实践
- **Objective-C**: [Objective-C 开发者指南](./guides/objective-c-guide.zh.md) - 完整的 Objective-C 指南和 API 参考

### 查看示例
- **[运行演示](./running-demos.zh.md)** - 如何运行演示应用
- **[Simple 示例](../demo-apps/iOS/Simple/)** - 使用高级 API 的完整 Swift 示例
- **[SimpleObjC 示例](../demo-apps/iOS/SimpleObjC/)** - 完整的 Objective-C 示例

### 自定义
- **[组件嵌入指南](./component-embedding.zh.md)** - 在弹出层、抽屉、标签页中嵌入聊天 UI
- **[构建工具指南](./build-tooling.zh.md)** - 使用 Makefile 和 XcodeGen 的可重现构建
- **[配置指南](./guides/configuration.zh.md)** - 完整配置参考

---

## 关键概念

### ChatKitCoordinator
管理运行时生命周期。在应用启动时创建**一次**，在整个应用中重复使用。

### startConversation
创建新的会话。当用户请求新聊天时调用此方法。

### ChatKitConversationViewController
现成的聊天 UI 组件。自动处理消息渲染、输入和所有聊天交互。

---

**准备好开始构建了吗？** 从[入门指南](./getting-started.zh.md)开始获取详细说明 →
