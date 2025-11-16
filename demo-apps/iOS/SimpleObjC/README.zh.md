# SimpleObjC 演示应用

Objective-C 演示应用，展示 ChatKit 的**高级 Objective-C API** 用于快速开发。此应用展示如何使用现成组件以最少的 Objective-C 代码构建完整的聊天应用程序。

> **📘 核心重点：高级 Objective-C API**  
>  
> 此示例演示了 ChatKit 的**高级 Objective-C API**：
> - `CKTChatKitCoordinator` - 运行时生命周期管理（无需包装器！）
> - `ChatKitConversationViewController` - 现成的聊天 UI 组件（兼容 ObjC）
> - `ChatKitConversationListViewController` - 现成的对话列表组件（兼容 ObjC）
> - 提供者定制支持
>  
> **结果**：在关键文件中仅用 **约 218 行代码**完成完整的 Objective-C 聊天应用  
> 直接使用高级组件 - 无需自定义包装器或样板代码！

## 🎯 概述

SimpleObjC 演示了：
- ✅ **高级 Objective-C API** - 为 ObjC 开发者提供的现成组件
- ✅ **远程二进制依赖** - 使用来自 GitHub 的 ChatKit（版本 0.6.1）
- ✅ **基于导航的流程** - 标准的 iOS 导航模式
- ✅ **持久化存储** - 自动对话持久化
- ✅ **多对话管理** - 多个同时进行的对话
- ✅ **构建工具** - 使用 Makefile 和 XcodeGen 的可重现构建

## 📦 功能特性

### 1. 高级组件使用

**ChatKitConversationViewController** - 现成的聊天 UI（兼容 ObjC）：
```objc
ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];
```

**ChatKitConversationListViewController** - 现成的列表 UI（兼容 ObjC）：
```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                              configuration:config];
```

### 2. Objective-C 协调器

**CKTChatKitCoordinator** - Objective-C 包装器：
```objc
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                       userId:@"demo-user"
                                                                     deviceId:nil];
config.storageMode = CKTStorageModePersistent;
CKTChatKitCoordinator *coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

### 3. 对话管理

- 通过协调器创建对话
- 带搜索功能的对话列表
- 恢复和删除对话
- 自动持久化

## 🚀 快速开始

### 前置要求

- macOS 14.0+
- Xcode 15.0+
- iOS 16.0+
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

此演示支持**两种构建系统**，以便您可以验证两种分发方法：

#### 选项 A – SPM（独立框架）
使用 `project.yml`、XcodeGen 和 Swift Package Manager 直接拉取 ChatKit + 依赖项。

```bash
cd demo-apps/iOS/SimpleObjC

# 从 project.yml 生成 Xcode 项目
make spm-generate

# 在 Xcode 中打开
make spm-open

# 或直接构建和运行
make spm-run
```

#### 选项 B – CocoaPods（捆绑分发）
使用 `project-cocoapods.yml`、CocoaPods 和发布工作流生成的单个捆绑 pod。

```bash
cd demo-apps/iOS/SimpleObjC

# 生成适用于 CocoaPods 的 Xcode 项目
make pod-project

# 安装捆绑依赖项（通过缓存 podspec 自动处理 SSL 问题）
make pod-install

# 通过工作区构建/运行
make pod-build
make pod-run
```

**构建工具**：此应用为两种流程使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) + Makefile。详见 [构建工具指南](../../docs/build-tooling.md)。

### 依赖项

应用使用 Swift Package Manager 从 GitHub 获取 ChatKit：
- **包名**：`https://github.com/Geeksfino/finclip-chatkit.git`
- **版本**：`0.6.1`

构建项目时，框架会自动解析为远程二进制依赖项。

## 📱 使用应用

### 首次启动

1. 出现**连接屏幕**
2. 点击 **"Connect"** 初始化协调器
3. 出现**对话列表**（首次启动时为空）

### 创建对话

1. 点击对话列表中的 **"+"** 按钮
2. **聊天视图**打开，显示空对话
3. 输入消息并按发送
4. 代理响应（需要后端服务器）

### 管理对话

- **恢复**：点击列表中的任何对话以继续
- **删除**：左滑对话并点击删除
- **搜索**：使用搜索栏查找对话
- **查看历史**：所有消息都会持久化并恢复

## 🏗️ 架构

```
SimpleObjC/
├── App/
│   ├── AppDelegate.h/m          # 应用委托
│   ├── SceneDelegate.h/m        # 场景委托（直接初始化协调器）
│   └── ViewControllers/         # 仅 2 个文件 - 薄包装器！
│       ├── ConversationListViewController.h/m  # 嵌入 ChatKitConversationListViewController
│       └── ChatViewController.h/m              # 直接使用 ChatKitConversationViewController
├── project.yml                  # XcodeGen 配置
└── Makefile                     # 构建自动化
```

### 关键架构要点

**最大化使用高级 Objective-C API**：
- `ConversationListViewController` - 将 `ChatKitConversationListViewController` **嵌入**为子控制器的薄包装器
- **零自定义协调器包装** - 直接使用 `CKTChatKitCoordinator`
- **无连接屏幕** - 协调器直接在 SceneDelegate 中初始化
- 框架自动处理所有列表管理、搜索、滑动删除

**注意**：ChatKit 视图控制器在 Swift 中标记为 `final`，因此 Objective-C 代码必须使用组合（嵌入为子视图控制器）而不是继承。

**在 ObjC 中您无需的内容**：
- ❌ 围绕 SDK 协调器的自定义 `ChatCoordinator` 包装器
- ❌ 自定义表格视图单元格或数据源实现
- ❌ 自定义搜索/过滤逻辑
- ❌ 连接管理 UI
- ❌ 模型类（直接使用 `CKTConversationRecord`）

**Objective-C 最佳实践**：
- 直接使用 `CKTChatKitCoordinator` - 无需包装！
- 通过 `@import FinClipChatKit` 访问 Swift 组件
- ObjC 友好的初始化器：`initWithObjCCoordinator:objcConfiguration:`
- 回调使用委托模式

## 💡 关键代码模式

### 初始化

```objc
// 在 ConnectionViewController 中
NSURL *serverURL = [NSURL URLWithString:@"http://127.0.0.1:3000/agent"];
CKTCoordinatorConfig *config = [[CKTCoordinatorConfig alloc] initWithServerURL:serverURL
                                                                         userId:@"demo-user"
                                                                       deviceId:nil];
config.storageMode = CKTStorageModePersistent;
self.coordinator = [[CKTChatKitCoordinator alloc] initWithConfig:config];
```

### 创建对话

```objc
[self.coordinator startConversationWithAgentId:agentId
                                           title:nil
                                       agentName:@"My Agent"
                                      completion:^(CKTConversationRecord *record, id conversation, NSError *error) {
    if (error) {
        NSLog(@"失败: %@", error);
        return;
    }
    
    // 显示聊天 UI
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

### 显示列表 UI

```objc
ChatKitConversationListViewController *listVC = 
    [[ChatKitConversationListViewController alloc] initWithObjCCoordinator:coordinator
                                                               configuration:[CKTConversationListConfiguration defaultConfiguration]];
listVC.delegate = self;
[self addChildViewController:listVC];
[self.view addSubview:listVC.view];
[listVC didMoveToParentViewController:self];
```

## 📚 学习资源

### 文档

- **[快速入门指南](../../docs/quick-start.md)** - 最小化骨架代码（包含 ObjC）
- **[API 级别指南](../../docs/api-levels.md)** - 高级 vs 低级 API
- **[组件嵌入指南](../../docs/component-embedding.md)** - 嵌入模式
- **[构建工具指南](../../docs/build-tooling.md)** - Makefile 和 XcodeGen
- **[Objective-C 指南](../../docs/objective-c-guide.md)** - Objective-C 特定模式

### 相关示例

- **[Simple](../Simple)** - 使用高级 API 的 Swift 版本

## 🐛 故障排除

### 构建错误

**"XcodeGen not found"**
- 安装：`brew install xcodegen`

**"Module 'ChatKit' not found"**
- 运行 `make generate` 重新生成项目
- 检查 `project.yml` 中是否有正确的包依赖
- 验证 Swift Package Manager 是否已解析依赖项

**"'RuntimeCoordinator.h' file not found"**
- 这是预期的 - 旧引用已被删除
- 改用 `CKTChatKitCoordinator`

### 运行时错误

**"Failed to create conversation"**
- 检查 `ConnectionViewController.m` 中的服务器 URL
- 确保后端服务器正在运行

**"Messages not persisting"**
- 验证 `storageMode` 设置为 `CKTStorageModePersistent`
- 检查 CoreData 容器初始化

## 🤝 贡献

发现问题或想要添加功能？请参阅 [CONTRIBUTING.md](../../../CONTRIBUTING.md) 了解指南。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](../../../LICENSE)

---

**由 FinClip 团队用 ❤️ 制作**
