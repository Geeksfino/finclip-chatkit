# 组件嵌入指南

ChatKit 组件设计为容器无关。它们可以嵌入到导航控制器、模态表单、抽屉、标签栏和任何其他容器中，而不对其父级做出假设。

---

## 组件理念

### 容器无关设计

ChatKit 组件（`ChatKitConversationViewController`、`ChatKitConversationListViewController`）不对以下内容做出假设：
- 父容器类型
- 导航结构
- 展示样式
- 布局约束

这使您可以在任何适合应用设计的场景中嵌入它们。

### 关键组件

#### ChatKitConversationViewController
现成的聊天 UI 组件，具有：
- 消息渲染（用户和代理消息）
- 支持富文本的输入编辑器
- 输入指示器
- 状态横幅
- 欢迎消息支持
- 上下文提供者集成
- 工具选择器集成

#### ChatKitConversationListViewController
现成的会话列表组件，具有：
- 带元数据的会话列表
- 搜索功能
- 滑动删除
- 长按操作
- 新建会话按钮
- 可自定义的标题

---

## 嵌入场景

### 1. 导航控制器（全屏）

最常见的模式 - 导航堆栈中的全屏聊天。

#### Swift

```swift
// 创建会话
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)

// 创建聊天视图控制器
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// 推入导航堆栈
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

**用例**：基于导航流程的标准聊天应用。

---

### 2. 模态表单展示

将聊天以模态表单形式展示（iOS 15+ 样式）。

#### Swift

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)

// 配置为表单
if let sheet = chatVC.sheetPresentationController {
    sheet.detents = [.medium(), .large()]
    sheet.prefersGrabberVisible = true
}

// 模态展示
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

// 配置为表单（iOS 15+）
if (@available(iOS 15.0, *)) {
    UISheetPresentationController *sheet = chatVC.sheetPresentationController;
    if (sheet) {
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent, 
                          UISheetPresentationControllerDetent.largeDetent];
        sheet.prefersGrabberVisible = YES;
    }
}

// 模态展示
[self presentViewController:chatVC animated:YES completion:nil];
```

**用例**：快速聊天覆盖、临时会话、帮助/支持聊天。

---

### 3. 抽屉/侧边栏容器

在抽屉或侧边栏中嵌入聊天（如 Simple 应用）。

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
        // 移除现有聊天
        if let existing = currentChatVC {
            existing.willMove(toParent: nil)
            existing.view.removeFromSuperview()
            existing.removeFromParent()
        }
        
        // 创建并添加新聊天
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
    // 移除现有聊天
    if (self.currentChatVC) {
        [self.currentChatVC willMoveToParentViewController:nil];
        [self.currentChatVC.view removeFromSuperview];
        [self.currentChatVC removeFromParentViewController];
    }
    
    // 创建并添加新聊天
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

**用例**：具有侧边导航的多会话应用、基于抽屉的 UI。

**参见**：
- `demo-apps/iOS/Simple/App/ViewControllers/DrawerContainerViewController.swift` - Swift 示例
- `demo-apps/iOS/SimpleObjC/` - Objective-C 模式

---

### 4. 标签栏项目

将聊天作为标签栏控制器中的标签嵌入。

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

**用例**：聊天作为一个功能的多功能应用。

---

### 5. 分栏视图控制器（iPad）

在 iPad 应用中嵌入到分栏视图中。

#### Swift

```swift
// 主视图：会话列表
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)

// 详细视图：聊天视图
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
// 主视图：会话列表
CKTConversationListConfiguration *listConfig = [CKTConversationListConfiguration defaultConfiguration];
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:listConfig];

// 详细视图：聊天视图
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

**用例**：具有主-详细布局的 iPad 应用。

---

### 6. 弹出窗口（iPad）

在弹出窗口中展示聊天。

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

**用例**：上下文聊天、快速帮助、内联辅助。

---

## 会话列表嵌入

### 抽屉/侧边栏

会话列表最常见的模式。

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
    
    // 实现委托方法
    func conversationListViewController(
        _ controller: ChatKitConversationListViewController,
        didSelectConversation record: ConversationRecord
    ) {
        drawerDelegate?.drawerDidSelectConversation(sessionId: record.id)
    }
}
```

**参见**：`demo-apps/iOS/Simple/App/ViewControllers/DrawerViewController.swift` 获取完整示例。

---

### 标签栏项目

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

### 导航控制器

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

## 自定义容器模式

### 抽屉容器模式

Simple 应用演示了抽屉容器模式：

```
DrawerContainerViewController
├── DrawerViewController (ChatKitConversationListViewController)
│   └── 带会话列表的侧边抽屉
└── MainChatViewController
    └── ChatKitConversationViewController
        └── 主聊天区域
```

**要点**：
- 抽屉滑动覆盖主内容
- 在抽屉中点击会话会切换主聊天
- 两个组件都是独立且可重用的

**参见**：`demo-apps/iOS/Simple/App/ViewControllers/DrawerContainerViewController.swift`

---

### 基于标签的导航

```
UITabBarController
├── 标签 1：ChatKitConversationListViewController
├── 标签 2：ChatKitConversationViewController
└── 标签 3：其他功能
```

**要点**：
- 每个标签都是独立的
- 可以在会话和聊天之间切换
- 简单的导航模式

---

### 分栏视图（iPad）

```
UISplitViewController
├── 主视图：ChatKitConversationListViewController
└── 详细视图：ChatKitConversationViewController
```

**要点**：
- 主视图显示会话列表
- 详细视图显示选定的会话
- 自动布局适应

---

## 配置

### ChatKitConversationConfiguration

自定义聊天 UI 行为：

#### Swift

```swift
var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "Hello! How can I help?" }
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0

// 上下文提供者
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [LocationContextProvider(), CalendarContextProvider()]
    }
}

// 工具
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

// 上下文提供者
config.contextProvidersProvider = ^NSArray * _Nonnull {
    return @[[[LocationContextProvider alloc] init], [[CalendarContextProvider alloc] init]];
};

// 工具
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

自定义列表 UI 行为：

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

## 生命周期管理

### 视图控制器生命周期

ChatKit 组件自动处理自己的生命周期：

- **viewDidLoad**：组件初始化
- **viewWillAppear**：组件准备显示
- **viewWillDisappear**：组件在需要时清理
- **deinit**：组件释放资源

**您不需要管理**：绑定/解绑、适配器生命周期、会话状态。

### 内存管理

组件自动：
- 在不可见时释放资源
- 管理会话绑定
- 清理订阅
- 处理后台/前台转换

---

## 最佳实践

### 1. 重用组件

创建一次组件并重用：

```swift
// ✅ 好：重用组件
private var chatVC: ChatKitConversationViewController?

func showConversation(record: ConversationRecord, conversation: Conversation) {
    if chatVC == nil {
        chatVC = ChatKitConversationViewController(...)
    }
    // 使用新会话更新
}
```

### 2. 正确的容器管理

使用标准的视图控制器包含：

```swift
// ✅ 好：正确的包含
addChild(chatVC)
view.addSubview(chatVC.view)
chatVC.didMove(toParent: self)

// ❌ 坏：直接添加视图
view.addSubview(chatVC.view) // 缺少包含调用
```

### 3. 针对用例的配置

针对不同场景使用不同配置：

```swift
// 全屏聊天
var fullScreenConfig = ChatKitConversationConfiguration.default
fullScreenConfig.showStatusBanner = true

// 表单聊天
var sheetConfig = ChatKitConversationConfiguration.default
sheetConfig.showStatusBanner = false // 在表单中不那么突兀
```

---

## 示例

### 完整的抽屉模式
参见：`demo-apps/iOS/Simple/App/ViewControllers/`

### Objective-C 模式
参见：`demo-apps/iOS/SimpleObjC/App/ViewControllers/`

---

## 下一步

- **[快速入门指南](./quick-start.zh.md)** - 开始使用组件（Swift 和 Objective-C）
- **[API 层级指南](./api-levels.zh.md)** - 了解组件 API
- **Swift**：[Swift 开发者指南](./guides/developer-guide.zh.md) - 全面的模式
- **Objective-C**：[Objective-C 开发者指南](./guides/objective-c-guide.zh.md) - 完整的 Objective-C 指南

---

**关键要点**：ChatKit 组件设计为可在任何地方工作。将它们嵌入到任何适合您应用设计的容器结构中。上述所有示例都提供了 Swift 和 Objective-C 两种版本。
