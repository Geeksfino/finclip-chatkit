# 配置指南

本指南涵盖 FinClip ChatKit 中所有可用于自定义聊天 UI 行为、外观和功能的配置选项。

---

## 目录

1. [ChatKitConversationConfiguration](#chatkitconversationconfiguration)
2. [ChatKitConversationListConfiguration](#chatkitconversationlistconfiguration)
3. [NeuronKitConfig 基础](#neuronkitconfig-基础)
4. [主题自定义](#主题自定义)
5. [提示启动器配置](#提示启动器配置)
6. [上下文提供器配置](#上下文提供器配置)
7. [性能配置](#性能配置)
8. [调试配置](#调试配置)

---

## ChatKitConversationConfiguration

`ChatKitConversationConfiguration` 为 `ChatKitConversationViewController` 提供自定义点，无需子类化或实现委托。

### 基本配置

```swift
import FinClipChatKit

var config = ChatKitConversationConfiguration.default

// 基本设置
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "你好！今天我能为您做些什么？" }

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### 状态横幅配置

控制连接状态横幅的外观和行为：

```swift
var config = ChatKitConversationConfiguration.default

// 显示/隐藏横幅
config.showStatusBanner = true

// 自动隐藏设置
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0  // 2 秒后隐藏

// 自定义样式
var bannerStyle = StatusBannerStyle.default
bannerStyle.height = 30.0
bannerStyle.font = .systemFont(ofSize: 12, weight: .medium)
bannerStyle.textColor = .white
bannerStyle.defaultColors = [
    "Connected": .systemGreen,
    "Connecting...": .systemOrange,
    "Reconnecting...": .systemOrange,
    "Disconnected": .systemRed
]
config.statusBannerStyle = bannerStyle

// 自定义颜色提供器
config.statusBannerColorProvider = { status in
    switch status {
    case "Connected": return .systemGreen
    case "Disconnected": return .systemRed
    default: return .systemOrange
    }
}
```

### 欢迎消息配置

```swift
var config = ChatKitConversationConfiguration.default

// 启用欢迎消息
config.showWelcomeMessage = true

// 静态消息
config.welcomeMessageProvider = { "欢迎！开始对话吧。" }

// 基于上下文的动态消息
config.welcomeMessageProvider = {
    if isFirstTimeUser {
        return "欢迎！我来帮您开始使用。"
    } else {
        return "欢迎回来！今天我能为您做些什么？"
    }
}
```

### 输入工具配置

注册在输入框中显示的工具：

```swift
var config = ChatKitConversationConfiguration.default

config.toolsProvider = {
    [
        FinConvoComposerTool(
            toolId: "camera",
            title: "相机",
            icon: UIImage(systemName: "camera.fill")
        ),
        FinConvoComposerTool(
            toolId: "photo",
            title: "照片库",
            icon: UIImage(systemName: "photo.fill")
        ),
        FinConvoComposerTool(
            toolId: "location",
            title: "位置",
            icon: UIImage(systemName: "location.fill")
        )
    ]
}
```

### 提示启动器配置

配置在新对话开始时显示的提示启动器：

```swift
var config = ChatKitConversationConfiguration.default

// 选项 1：使用工厂预设
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

// 选项 2：创建自定义启动器
config.promptStartersProvider = {
    [
        FinConvoPromptStarter(
            starterId: "email",
            title: "写一封专业邮件",
            subtitle: nil,
            icon: UIImage(systemName: "envelope.fill"),
            payload: nil
        ),
        FinConvoPromptStarter(
            starterId: "brainstorm",
            title: "帮我头脑风暴",
            subtitle: "创造性思维",
            icon: UIImage(systemName: "lightbulb.fill"),
            payload: nil
        )
    ]
}

// 可选：处理启动器选择
config.onPromptStarterSelected = { starter in
    print("选择的启动器：\(starter.title)")
    return false // false = 自动发送消息
}

// 可选：自定义样式
let style = FinConvoPromptStarterStyle()
style.backgroundColor = .systemGray6
style.textColor = .label
config.promptStarterStyle = style

// 可选：配置行为模式（默认：.autoHide）
// 使用 .manual 允许程序化重新显示启动器
config.promptStarterBehaviorMode = .manual

// 可选：插入到输入框而不是自动发送（默认：false）
// 当为 true 时，点击启动器会将文本插入到输入框中供用户查看
config.promptStarterInsertToComposerOnTap = true
```

> **📘 有关详细的提示启动器配置，请参阅 [提示启动器指南](./prompt-starters.zh.md)**

### 上下文提供器配置

配置用于丰富消息的上下文提供器：

```swift
var config = ChatKitConversationConfiguration.default

config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            LocationContextProvider(),
            CalendarContextProvider(),
            DeviceStateProvider()
        ]
    }
}
```

> **📘 有关详细的上下文提供器配置，请参阅 [上下文提供器指南](./context-providers.zh.md)**

### 完整配置示例

```swift
var config = ChatKitConversationConfiguration.default

// 状态横幅
config.showStatusBanner = true
config.statusBannerAutoHide = true
config.statusBannerAutoHideDelay = 2.0

// 欢迎消息
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "你好！我能帮您什么？" }

// 提示启动器
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}
config.promptStarterBehaviorMode = .autoHide
config.promptStarterInsertToComposerOnTap = false

// 工具
config.toolsProvider = {
    [CameraTool(), PhotoLibraryTool()]
}

// 上下文提供器
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [LocationContextProvider()]
    }
}

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Objective-C 配置

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];

// 状态横幅
config.showStatusBanner = YES;
config.statusBannerAutoHide = YES;
config.statusBannerAutoHideDelay = 2.0;
config.statusBannerHeight = 30.0;
config.statusBannerTextColor = [UIColor whiteColor];
config.statusBannerConnectedColor = [UIColor systemGreenColor];

// 欢迎消息
config.showWelcomeMessage = YES;
config.welcomeMessage = @"你好！我能帮您什么？";

// 提示启动器
config.promptStartersEnabled = YES;
config.promptStarters = [ChatKitPromptStarterFactory createExampleStarters];
config.promptStarterBehaviorMode = FinConvoPromptStarterBehaviorModeAutoHide;
config.promptStarterInsertToComposerOnTap = NO;

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                       conversation:conversation
                                                    objcCoordinator:coordinator
                                                  objcConfiguration:config];
```

### 配置属性参考

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `showStatusBanner` | `Bool` | `true` | 是否显示连接状态横幅 |
| `showWelcomeMessage` | `Bool` | `true` | 是否显示欢迎消息 |
| `welcomeMessageProvider` | `() -> String?` | `nil` | 欢迎消息文本提供器 |
| `statusBannerStyle` | `StatusBannerStyle` | `.default` | 状态横幅样式配置 |
| `statusBannerAutoHide` | `Bool` | `true` | 连接后是否自动隐藏横幅 |
| `statusBannerAutoHideDelay` | `TimeInterval` | `2.0` | 自动隐藏延迟（秒） |
| `statusBannerColorProvider` | `(String) -> UIColor?` | `nil` | 状态的自定义颜色提供器 |
| `promptStartersProvider` | `() -> [FinConvoPromptStarter]?` | `nil` | 提示启动器提供器 |
| `onPromptStarterSelected` | `(FinConvoPromptStarter) -> Bool?` | `nil` | 点击启动器时的回调 |
| `promptStarterStyle` | `FinConvoPromptStarterStyle?` | `nil` | 启动器样式配置 |
| `promptStarterBehaviorMode` | `FinConvoPromptStarterBehaviorMode` | `.autoHide` | 行为模式（`.autoHide` 或 `.manual`） |
| `promptStarterInsertToComposerOnTap` | `Bool` | `false` | 插入到输入框而不是自动发送 |
| `toolsProvider` | `() -> [FinConvoComposerTool]?` | `nil` | 输入工具提供器 |
| `contextProvidersProvider` | `() -> [FinConvoComposerContextProvider]?` | `nil` | 上下文提供器提供器 |

---

## ChatKitConversationListConfiguration

`ChatKitConversationListConfiguration` 为 `ChatKitConversationListViewController` 提供自定义点。

### 基本配置

```swift
import FinClipChatKit

var config = ChatKitConversationListConfiguration.default

// 搜索配置
config.searchPlaceholder = "搜索对话"
config.showSearchBar = true
config.searchEnabled = true

// 标题配置
config.showHeader = true
config.headerTitle = "对话"
config.headerIcon = UIImage(systemName: "message.fill")

// 新建对话按钮
config.showNewButton = true

// 单元格配置
config.cellStyle = .default
config.rowHeight = 56.0
config.enableSwipeToDelete = true
config.enableLongPress = true

let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

### 单元格样式

```swift
var config = ChatKitConversationListConfiguration.default

// 默认样式（侧边栏样式，带标题和预览）
config.cellStyle = .default

// 紧凑样式（仅标题）
config.cellStyle = .compact

// 自定义样式（应用通过委托提供单元格）
config.cellStyle = .custom
```

### Objective-C 配置

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationListConfiguration *config = [CKTConversationListConfiguration defaultConfiguration];

config.searchPlaceholder = @"搜索对话";
config.showSearchBar = YES;
config.showHeader = YES;
config.headerTitle = @"对话";
config.showNewButton = YES;
config.rowHeight = 56.0;

ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithCoordinator:coordinator
                                                          configuration:config];
```

### 配置属性参考

| 属性 | 类型 | 默认值 | 描述 |
|------|------|--------|------|
| `searchPlaceholder` | `String` | `"Search"` | 搜索栏占位符文本 |
| `headerTitle` | `String?` | `nil` | 标题文本（nil 隐藏标题） |
| `headerIcon` | `UIImage?` | `nil` | 标题图标图像 |
| `showHeader` | `Bool` | `true` | 是否显示标题部分 |
| `showSearchBar` | `Bool` | `true` | 是否显示搜索栏 |
| `showNewButton` | `Bool` | `true` | 是否显示新建对话按钮 |
| `cellStyle` | `CellStyle` | `.default` | 单元格样式（`.default`、`.compact`、`.custom`） |
| `enableSwipeToDelete` | `Bool` | `true` | 是否启用滑动删除 |
| `enableLongPress` | `Bool` | `true` | 是否启用长按操作 |
| `searchEnabled` | `Bool` | `true` | 是否启用搜索功能 |
| `rowHeight` | `CGFloat` | `56.0` | 对话单元格的行高 |

---

## NeuronKitConfig 基础

`NeuronKitConfig` 用于初始化 `ChatKitCoordinator`，它管理运行时生命周期。

### 基本配置

```swift
import FinClipChatKit
import NeuronKit

let config = NeuronKitConfig(
    serverURL: URL(string: "wss://your-server.com")!,
    deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
    userId: "user-123",
    storage: .persistent
)

let coordinator = ChatKitCoordinator(config: config)
```

### 存储配置

选择持久化或内存存储：

```swift
// 持久化存储（推荐用于生产环境）
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .persistent  // 保存到 CoreData
)

// 内存存储（仅用于测试）
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .inMemory  // 应用重启后丢失
)
```

### NeuronKitConfig 中的上下文提供器

在运行时级别添加上下文提供器：

```swift
let config = NeuronKitConfig(
    serverURL: serverURL,
    deviceId: deviceId,
    userId: userId,
    storage: .persistent,
    contextProviders: [
        DeviceStateProvider(updatePolicy: .every(60)),       // 电池、存储
        NetworkStatusProvider(updatePolicy: .every(30)),     // 网络类型
        CalendarPeekProvider(updatePolicy: .onAppForeground) // 即将到来的事件
    ]
)
```

**可用的更新策略**：
- `.every(seconds)` - 定期更新
- `.onAppForeground` - 应用进入前台时更新
- `.onDemand` - 仅在明确请求时更新

> **📘 注意**：上下文提供器也可以通过 `ChatKitConversationConfiguration.contextProvidersProvider` 配置，用于对话特定的提供器。

---

## 主题自定义

使用 `FinConvoTheme` 自定义聊天 UI 的外观。

### 基本主题设置

```swift
import ConvoUI

let chatView = FinConvoChatView()
let theme = FinConvoTheme.default()

// 自定义并应用
chatView.theme = theme
```

### 颜色自定义

```swift
let theme = FinConvoTheme.default()

// 主色调
theme.primaryColor = .systemBlue
theme.backgroundColor = .systemBackground

// 消息气泡
theme.userMessageBackgroundColor = .systemBlue
theme.userMessageTextColor = .white
theme.agentMessageBackgroundColor = .systemGray5
theme.agentMessageTextColor = .label

// 输入区域
theme.inputBackgroundColor = .secondarySystemBackground
theme.inputTextColor = .label
theme.sendButtonColor = .systemBlue

chatView.theme = theme
```

### 字体自定义

```swift
let theme = FinConvoTheme.default()

// 消息文本
theme.messageFont = .systemFont(ofSize: 16, weight: .regular)
theme.messageFontBold = .systemFont(ofSize: 16, weight: .bold)

// 时间戳
theme.timestampFont = .systemFont(ofSize: 12, weight: .light)

// 输入
theme.inputFont = .systemFont(ofSize: 16)

chatView.theme = theme
```

### 间距自定义

```swift
let theme = FinConvoTheme.default()

// 消息间距
theme.messageSpacing = 8.0
theme.messagePadding = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

// 气泡圆角半径
theme.messageCornerRadius = 18.0

chatView.theme = theme
```

### 深色模式支持

使用系统颜色时，ChatKit 主题会自动适应深色模式：

```swift
let theme = FinConvoTheme.default()

// 使用自适应颜色
theme.backgroundColor = .systemBackground           // 自动适应
theme.userMessageBackgroundColor = .systemBlue      // 两种模式都可用
theme.agentMessageBackgroundColor = .systemGray5    // 自动适应

chatView.theme = theme
```

---

## 提示启动器配置

有关详细的提示启动器配置，请参阅 [提示启动器指南](./prompt-starters.zh.md)。

### 快速参考

```swift
var config = ChatKitConversationConfiguration.default

// 启用提示启动器
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

// 行为模式
config.promptStarterBehaviorMode = .manual  // 或 .autoHide

// 点击操作
config.promptStarterInsertToComposerOnTap = true  // 或 false
```

---

## 上下文提供器配置

有关详细的上下文提供器配置，请参阅 [上下文提供器指南](./context-providers.zh.md)。

### 快速参考

```swift
var config = ChatKitConversationConfiguration.default

config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            LocationContextProvider(),
            CalendarContextProvider(),
            DeviceStateProvider()
        ]
    }
}
```

---

## 性能配置

### 消息渲染优化

```swift
let chatView = FinConvoChatView()

// 限制可见消息数量以提高性能
chatView.maxVisibleMessages = 100

// 启用延迟加载（如果支持）
// chatView.enableLazyLoading = true
```

### 内存管理

```swift
class ChatViewController: ChatKitConversationViewController {
    deinit {
        // 清理资源
        conversation?.unbindUI()
    }
}
```

---

## 调试配置

### 启用调试日志

```swift
// 启用详细日志（仅在 DEBUG 构建中）
#if DEBUG
// ChatKit 日志由 NeuronKit 控制
// 查看 NeuronKit 文档了解调试日志选项
#endif
```

### 布局验证

使用 `ChatKitConversationViewController` 时，布局验证会自动处理。对于自定义实现：

```swift
let chatView = FinConvoChatView()

// 检查布局问题
chatView.setNeedsLayout()
chatView.layoutIfNeeded()
```

---

## 环境特定配置

### 开发环境配置

```swift
#if DEBUG
let config = NeuronKitConfig(
    serverURL: URL(string: "wss://dev-server.com")!,
    deviceId: "dev-device",
    userId: "test-user",
    storage: .inMemory  // 开发环境不持久化
)
#endif
```

### 生产环境配置

```swift
#if RELEASE
let config = NeuronKitConfig(
    serverURL: URL(string: "wss://prod-server.com")!,
    deviceId: UIDevice.current.identifierForVendor!.uuidString,
    userId: currentUser.id,
    storage: .persistent  // 生产环境持久化
)
#endif
```

---

## 下一步

- **[开发者指南](./developer-guide.zh.md)** - 高级模式和示例
- **[Objective-C 指南](./objective-c-guide.zh.md)** - Objective-C 特定配置
- **[提示启动器指南](./prompt-starters.zh.md)** - 详细的提示启动器配置
- **[上下文提供器指南](./context-providers.zh.md)** - 详细的上下文提供器配置
- **[故障排除](../troubleshooting.zh.md)** - 常见问题和解决方案

---

**最后更新**：2025 年 11 月  
**ChatKit 版本**：0.9.0+

