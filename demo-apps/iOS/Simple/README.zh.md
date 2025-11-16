# Simple 演示应用

一个展示 ChatKit **高级 API** 快速开发能力的演示应用。此应用展示如何使用现成组件以最少代码构建完整的聊天应用程序。

> **📘 核心重点：高级 API**  
>  
> 此示例演示了 ChatKit 的**高级 API**：
> - `ChatKitCoordinator` - 运行时生命周期管理
> - `ChatKitConversationViewController` - 现成的聊天 UI 组件
> - `ChatKitConversationListViewController` - 现成的对话列表组件
> - 提供者定制（上下文提供者、工具）
>  
> **结果**：在 ViewController 中仅用 **约 477 行代码**完成完整聊天应用（相比低级 API 需要 1000+ 行）  
> 使用高级组件消除样板代码 - 无需自定义列表/单元格实现！

## 🎯 概述

Simple 演示了：
- ✅ **高级 API** - 用于快速开发的现成组件
- ✅ **组件嵌入** - 基于抽屉的导航模式
- ✅ **提供者定制** - 上下文提供者（日历、位置）
- ✅ **持久化存储** - 自动对话持久化
- ✅ **多对话管理** - 多个同时进行的对话
- ✅ **构建工具** - 使用 Makefile 和 XcodeGen 的可重现构建

## 📦 功能特性

### 1. 高级组件使用

**ChatKitConversationViewController** - 现成的聊天 UI：
```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

**ChatKitConversationListViewController** - 现成的列表 UI：
```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

### 2. 提供者定制

- **上下文提供者** - 日历和位置上下文
- **工具提供者** - 自定义撰写工具
- **欢迎消息** - 可定制的欢迎消息

### 3. 抽屉模式

- 带对话列表的侧边抽屉
- 主聊天区域
- 对话之间无缝切换

## 🚀 快速开始

### 前置要求

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- XcodeGen (`brew install xcodegen`)
- **Node.js 20+**（用于后端服务器）

### 后端服务器设置

**重要**：此演示需要运行后端服务器。请先启动服务器：

```bash
# 在单独的终端窗口中
cd ../../server/agui-test-server
npm install
npm run dev
```

服务器将在 `http://localhost:3000` 上启动。

**参见**：[服务器文档](../../server/README.md) 了解详细的服务器设置、配置选项和故障排除。

### 构建应用

```bash
cd demo-apps/iOS/Simple

# 从 project.yml 生成 Xcode 项目
make generate

# 在 Xcode 中打开
make open

# 或直接构建和运行
make run
```

**构建工具**：此应用使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 和 Makefile 进行可重现构建。详见 [构建工具指南](../../docs/build-tooling.md)。

### 依赖项

应用使用 Swift Package Manager 从 GitHub 获取 ChatKit：
- **包名**：`https://github.com/Geeksfino/finclip-chatkit.git`
- **版本**：`0.6.1`

## 📱 使用应用

### 首次启动

1. 应用启动时抽屉处于关闭状态
2. 点击菜单按钮打开抽屉
3. 点击 "+" 创建新对话
4. 聊天视图自动打开

### 创建对话

1. 点击抽屉中的 **"+"** 按钮
2. **聊天视图**打开，显示空对话
3. 输入消息并按发送
4. 代理响应（需要后端服务器）

### 管理对话

- **恢复**：点击抽屉中的任何对话以切换
- **删除**：在抽屉中左滑对话
- **搜索**：使用抽屉中的搜索栏查找对话
- **查看历史**：所有消息都会持久化并恢复

## 🏗️ 架构

```
Simple/
├── App/
│   ├── App/
│   │   ├── SceneDelegate.swift            # 初始化 ChatKitCoordinator（无连接屏幕！）
│   │   ├── AppConfig.swift                # 应用配置常量
│   │   ├── ComposerToolsExample.swift     # 撰写工具演示
│   │   └── LocalizationHelper.swift       # 国际化工具
│   ├── Extensions/
│   │   ├── ChatContextProviders.swift        # 提供者工厂
│   │   ├── CalendarContextProvider.swift     # 日历上下文提供者
│   │   └── LocationContextProvider.swift     # 位置上下文提供者
│   └── ViewControllers/                      # 仅 4 个文件 - 总共 477 行！
│       ├── DrawerContainerViewController.swift    # 抽屉容器（155 行）
│       ├── DrawerViewController.swift             # ChatKitConversationListViewController 的薄包装器（64 行）
│       ├── MainChatViewController.swift            # 主聊天容器（220 行）
│       └── ChatViewController.swift               # ChatKitConversationViewController 的薄包装器（38 行）
├── project.yml                             # XcodeGen 配置
└── Makefile                                # 构建自动化
```

### 关键架构要点

**最大化使用高级 API**：
- `DrawerViewController` - 64 行对 `ChatKitConversationListViewController` 的薄包装
- `ChatViewController` - 38 行对 `ChatKitConversationViewController` 的薄包装
- **零自定义列表/单元格实现** - 框架处理一切
- **无连接屏幕** - 协调器直接在 SceneDelegate 中初始化

**您无需实现的内容**：
- ❌ 对话的自定义表格视图单元格
- ❌ 自定义搜索/过滤逻辑
- ❌ 自定义滑动删除处理器
- ❌ 自定义空状态视图
- ❌ 连接管理 UI

**容器无关设计**：
- 抽屉模式展示灵活性
- 组件可在导航堆栈、工作表、抽屉、标签中工作
- 只需配置并呈现 - 框架处理其余部分

## 💡 关键代码模式

### 初始化

```swift
// 在 SceneDelegate 中
let config = NeuronKitConfig.default(serverURL: AppConfig.defaultServerURL)
    .withUserId(AppConfig.defaultUserId)
let coordinator = ChatKitCoordinator(config: config)
```

### 创建对话

```swift
let (record, conversation) = try await coordinator.startConversation(
    agentId: AppConfig.defaultAgentId,
    title: nil,
    agentName: AppConfig.defaultAgentName
)
```

### 显示聊天 UI

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### 显示列表 UI

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: config
)
```

## 🔧 配置

### ChatKitConversationConfiguration

```swift
var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true
config.welcomeMessageProvider = { "您好！我能帮您什么？" }
config.toolsProvider = { ComposerToolsExample.createExampleTools() }
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        ChatContextProviderFactory.makeDefaultProviders()
    }
}
```

### ChatKitConversationListConfiguration

```swift
var config = ChatKitConversationListConfiguration.default
config.headerTitle = "Simple"
config.showSearchBar = true
config.showNewButton = true
config.enableSwipeToDelete = true
```

## 📚 学习资源

### 文档

- **[快速入门指南](../../docs/quick-start.md)** - 最小化骨架代码
- **[API 级别指南](../../docs/api-levels.md)** - 高级 vs 低级 API
- **[组件嵌入指南](../../docs/component-embedding.md)** - 嵌入模式
- **[构建工具指南](../../docs/build-tooling.md)** - Makefile 和 XcodeGen

### 相关示例

- **[SimpleObjC](../SimpleObjC)** - 使用高级 API 的 Objective-C 版本

## 🐛 故障排除

### 构建错误

**"XcodeGen not found"**
- 安装：`brew install xcodegen`

**"Module 'ChatKit' not found"**
- 运行 `make generate` 重新生成项目
- 检查 `project.yml` 中是否有正确的包依赖

### 运行时错误

**"Failed to create conversation"**
- 检查 `AppConfig.swift` 中的服务器 URL
- 确保后端服务器正在运行

**"Messages not persisting"**
- 默认启用持久化存储
- 检查 CoreData 容器初始化

## 🤝 贡献

发现问题或想要添加功能？请参阅 [CONTRIBUTING.md](../../../CONTRIBUTING.md) 了解指南。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](../../../LICENSE)

---

**由 FinClip 团队用 ❤️ 制作**
