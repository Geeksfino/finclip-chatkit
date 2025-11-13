# Objective-C 开发者指南

在 Objective-C 中构建 ChatKit 应用的完整指南。本指南涵盖了从基本设置到高级模式的所有内容，并提供全面的示例。

> **📘 刚接触 ChatKit？** 从 [Objective-C 快速开始](../getting-started.zh.md#objective-c-快速开始) 开始，5 分钟即可完成设置。
> 
> **📘 Swift 开发者？** 参见 [Swift 开发者指南](./developer-guide.zh.md)。

---

## 目录

1. [快速开始](#快速开始)
2. [基本使用](#基本使用)
3. [多个会话](#多个会话)
4. [会话列表 UI](#会话列表-ui)
5. [组件嵌入](#组件嵌入)
6. [提供器自定义](#提供器自定义)
7. [API 参考](#api-参考)

---

## 快速开始

### 前置条件

- **Xcode 15.0+**
- **iOS 16.0+** 部署目标
- **Objective-C** 项目

### 步骤 1：添加依赖

在您的 `Package.swift` 中添加，或在 Xcode 中配置：

```swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.6.1")
]
```

### 步骤 2：导入 ChatKit

在您的 Objective-C 文件中：

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>
```

或使用模块导入：

```objc
@import FinClipChatKit;
```

### 步骤 3：初始化协调器

在您的 `SceneDelegate.m` 或 `AppDelegate.m` 中：

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
    window.rootViewController = [[UINavigationController alloc] initWithRootViewController:rootVC];
    [window makeKeyAndVisible];
    
    self.window = window;
}

@end
```

### 步骤 4：创建会话并显示聊天

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
        
        // 显示现成的聊天 UI
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

**就是这样！** 您现在拥有一个可用的 Objective-C AI 聊天应用。

---

## 基本使用

### 理解协调器

`CKTChatKitCoordinator` 是 Objective-C 开发者的主要入口点。它管理运行时生命周期并提供创建会话的方法。

#### 初始化

```objc
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent; // 或 CKTStorageModeInMemory

CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

#### 配置选项

- **`serverURL`**：您的 AI 代理服务器 URL（必需）
- **`userId`**：唯一用户标识符（必需）
- **`deviceId`**：设备标识符（可选，nil = 自动生成）
- **`storageMode`**：`CKTStorageModePersistent` 或 `CKTStorageModeInMemory`

### 创建会话

使用协调器的 `startConversationWithAgentId:title:agentName:completion:` 方法：

```objc
NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];

[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        // 处理错误
        NSLog(@"错误: %@", error.localizedDescription);
        return;
    }
    
    // 使用 record 和 conversation
    // record: 带有元数据的 ConversationRecord（id、标题等）
    // conversation: 用于发送消息的 Conversation 实例
}];
```

### 显示聊天 UI

使用 `ChatKitConversationViewController` - 一个现成的组件：

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;
config.welcomeMessageProvider = ^NSString * _Nullable {
    return @"你好！有什么可以帮助您的？";
};

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];

[self.navigationController pushViewController:chatVC animated:YES];
```

### 配置选项

```objc
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];

// UI 选项
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;
config.welcomeMessageProvider = ^NSString * _Nullable {
    return @"欢迎！";
};

// 状态横幅
config.statusBannerAutoHide = YES;
config.statusBannerAutoHideDelay = 2.0;

// 工具提供器（可选）
config.toolsProvider = ^NSArray * _Nonnull {
    // 返回工具数组
    return @[];
};

// 上下文提供器（可选）
config.contextProvidersProvider = ^NSArray * _Nonnull {
    // 返回上下文提供器数组
    return @[];
};
```

---

## 多个会话

对于需要管理多个会话的应用，使用 `CKTConversationManager`。

### 设置管理器

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
        // 初始化协调器
        NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
        CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                                 userId:@"demo-user"
                                                                               deviceId:nil];
        config.storageMode = CKTStorageModePersistent;
        _coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
        
        // 初始化会话管理器
        _conversationManager = [[CKTConversationManager alloc] init];
        [_conversationManager attachToCoordinator:_coordinator];
    }
    return self;
}

@end
```

### 创建会话

```objc
NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];

[self.conversationManager createConversationWithAgentId:agentId
                                                   title:nil
                                               agentName:@"My Agent"
                                               deviceId:nil
                                              completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        NSLog(@"创建会话失败: %@", error);
        return;
    }
    
    // 显示聊天 UI
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

### 观察会话更新

使用 `recordsPublisher` 观察会话列表的变化：

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
    
    // 订阅会话更新
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

**注意**：Combine 是一个 Swift 框架。对于纯 Objective-C，使用委托模式或 KVO。参见下面的[委托模式](#委托模式)。

### 恢复会话

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

### 删除会话

```objc
- (void)deleteConversation:(CKTConversationRecord *)record {
    [self.conversationManager deleteConversationWithSessionId:record.id];
    // recordsPublisher 将自动发出更新后的列表
}
```

---

## 会话列表 UI

ChatKit 提供 `ChatKitConversationListViewController` - 一个现成的会话列表组件。

### 使用现成组件

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
        
        // 配置列表组件
        CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];
        config.headerTitle = @"会话";
        config.searchPlaceholder = @"搜索会话...";
        config.showHeader = YES;
        config.showSearchBar = YES;
        config.showNewButton = YES;
        config.enableSwipeToDelete = YES;
        config.enableLongPress = NO;
        config.rowHeight = 72.0;
        
        // 创建列表视图控制器
        _listViewController = [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                                                      objcConfiguration:config];
        _listViewController.objcDelegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 嵌入列表视图控制器
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
    // 用户选择了一个会话
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
    // 用户点击了"新建"按钮
    NSUUID *agentId = [[NSUUID alloc] initWithUUIDString:@"E1E72B3D-845D-4F5D-B6CA-5550F2643E6B"];
    
    [self.coordinator startConversationWithAgentId:agentId
                                               title:nil
                                           agentName:@"My Agent"
                                          completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
        if (error) {
            NSLog(@"失败: %@", error);
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
    // 处理置顶操作（可选）
    NSLog(@"置顶会话: %@", record.title);
}

@end
```

### 配置选项

```objc
CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];

// 标题
config.headerTitle = @"我的聊天";
config.headerIcon = [UIImage systemImageNamed:@"message.fill"];
config.showHeader = YES;

// 搜索
config.showSearchBar = YES;
config.searchPlaceholder = @"搜索会话...";
config.searchEnabled = YES;

// 操作
config.showNewButton = YES;
config.enableSwipeToDelete = YES;
config.enableLongPress = YES;

// 外观
config.rowHeight = 72.0;
```

---

## 组件嵌入

ChatKit 组件与容器无关。它们可以嵌入到导航控制器、模态表单、抽屉和标签中。

### 导航控制器

```objc
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];

[self.navigationController pushViewController:chatVC animated:YES];
```

### 模态表单

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

### 抽屉/侧边栏

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

### 标签栏

```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              objcConfiguration:config];
listVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"聊天" 
                                                   image:[UIImage systemImageNamed:@"list.bullet"] 
                                                     tag:0];

UITabBarController *tabBarController = [[UITabBarController alloc] init];
tabBarController.viewControllers = @[listVC, otherViewController];
```

---

## 提供器自定义

### 上下文提供器

将上下文信息（位置、日历事件）附加到消息：

```objc
#import <ConvoUI/ConvoUI.h>

@interface LocationContextProvider : NSObject <FinConvoComposerContextProvider>
@end

@implementation LocationContextProvider

- (void)provideContextWithCompletion:(void (^)(FinConvoContext * _Nullable))completion {
    // 您的位置逻辑
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    // ... 获取位置 ...
    
    FinConvoContext *context = [[FinConvoContext alloc] initWithTitle:@"当前位置"
                                                               content:@"纬度: 37.7749, 经度: -122.4194"];
    completion(context);
}

@end

// 在配置中注册
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.contextProvidersProvider = ^NSArray * _Nonnull {
    return @[[[LocationContextProvider alloc] init]];
};
```

### ASR 提供器

自定义语音输入的自动语音识别：

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 您的 ASR 实现（例如，OpenAI Whisper、Google Speech-to-Text）
    // 处理音频并返回转录文本
    NSString *transcribedText = @"转录文本在这里";
    completion(transcribedText, nil);
}

- (void)cancelTranscription {
    // 取消任何正在进行的请求
}

@end

// 在配置中注册
CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
// ASR 提供器注册通过 ConvoUI 配置处理
```

### 标题生成提供器

自定义会话标题生成：

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface MyTitleProvider : NSObject <CKTConversationTitleProvider>
@end

@implementation MyTitleProvider

- (void)shouldGenerateTitleForSessionId:(NSString *)sessionId
                           messageCount:(NSInteger)messageCount
                           currentTitle:(NSString *)currentTitle
                             completion:(void (^)(BOOL))completion {
    // 当应该生成标题时返回 YES
    completion(messageCount >= 3 && currentTitle == nil);
}

- (void)generateTitleForSessionId:(NSString *)sessionId
                         messages:(NSArray *)messages
                       completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 您的标题生成逻辑
    // messages 是包含消息数据的字典数组
    [self callLLMForTitle:messages completion:^(NSString *title, NSError *error) {
        completion(title, error);
    }];
}

@end

// 创建管理器时注册
CKTConversationManager *manager = [[CKTConversationManager alloc] initWithTitleProvider:[[MyTitleProvider alloc] init]];
```

---

## API 参考

### CKTChatKitCoordinator

管理运行时和会话的主协调器。

```objc
@interface CKTChatKitCoordinator : NSObject

- (instancetype)initWithConfig:(CKTCoordinatorConfig *)config;

- (void)startConversationWithAgentId:(NSUUID *)agentId
                                title:(NSString *)title
                            agentName:(NSString *)agentName
                           completion:(void (^)(CKTConversationRecord *, id, NSError *))completion;

- (id)conversationForSessionId:(NSUUID *)sessionId;
- (void)deleteConversationWithSessionId:(NSUUID *)sessionId;

@property (nonatomic, readonly) id runtime; // NeuronRuntime（不透明）

@end
```

### CKTConversationManager

管理多个会话。

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

@property (nonatomic, readonly) id<Publisher> recordsPublisher; // Combine 发布器

@end
```

### ChatKitConversationViewController

现成的聊天 UI 组件。

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

现成的会话列表组件。

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

## 常见模式

### 委托模式（Combine 的替代方案）

如果您更喜欢委托而不是 Combine：

```objc
@protocol ConversationManagerDelegate <NSObject>
- (void)conversationManager:(CKTConversationManager *)manager 
         didUpdateRecords:(NSArray<CKTConversationRecord *> *)records;
@end

// 在您的视图控制器中
- (void)observeConversations {
    // 使用 KVO 或轮询而不是 Combine
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

### 错误处理

```objc
[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController 
                alertControllerWithTitle:@"错误"
                                 message:error.localizedDescription
                          preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确定" 
                                                      style:UIAlertActionStyleDefault 
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
    
    // 成功 - 继续会话
}];
```

---

## 下一步

- **[Swift 开发者指南](./developer-guide.zh.md)** - 查看 Swift 示例进行比较
- **[组件嵌入指南](../component-embedding.zh.md)** - 更多嵌入场景
- **[API 层级指南](../api-levels.zh.md)** - 理解高级与低级 API
- **[SimpleObjC 演示](../../demo-apps/iOS/SimpleObjC/)** - 完整的工作示例

---

**准备好开始构建了吗？** 从 [Objective-C 快速开始](../getting-started.zh.md#objective-c-快速开始) 开始 →
