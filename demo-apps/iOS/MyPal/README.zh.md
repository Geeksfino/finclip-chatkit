# MyPal 演示应用

一个展示 ChatKit 与**本地 LLM 支持**的演示应用，通过 MLX-Swift 使用 Google Gemma 270M。此应用在 Simple 演示的基础上扩展了离线 AI 功能。

> **📘 核心功能：本地 LLM 集成**  
>  
> 此应用演示了：
> - 通过 MLX-Swift 使用 Google Gemma 270M 进行本地 LLM 推理
> - 在在线（远程服务器）和离线（本地 LLM）模式之间无缝切换
> - URLProtocol 拦截模式（类似 MyChatGPT 的 MockSSEURLProtocol）
> - 复用现有的 AGUI_Adapter 基础设施

## 🎯 概述

MyPal 演示了：
- ✅ **本地 LLM 支持** - 通过 MLX-Swift 在设备上运行 Google Gemma 270M
- ✅ **双模式操作** - 在远程服务器和本地 LLM 之间切换
- ✅ **高级 API** - 与 Simple 演示相同的 ChatKit 高级 API
- ✅ **组件嵌入** - 基于抽屉的导航模式
- ✅ **持久化存储** - 自动对话持久化
- ✅ **构建工具** - 使用 Makefile 和 XcodeGen 的可重现构建

## 📦 功能特性

### 1. 本地 LLM 集成

**通过 MLX-Swift 使用 Gemma 270M：**
- 使用 Apple 优化的 MLX 框架进行设备端推理
- 首次激活本地模式时下载模型
- 与现有 ChatKit 基础设施无缝集成

### 2. 模式切换

**远程 vs 本地：**
- 在远程服务器和本地 LLM 模式之间切换
- 相同的 UI 和对话体验
- 切换到本地模式时自动下载模型

### 3. 高级组件使用

与 Simple 演示相同：
- `ChatKitCoordinator` - 运行时生命周期管理
- `ChatKitConversationViewController` - 现成的聊天 UI
- `ChatKitConversationListViewController` - 现成的列表 UI

## 🚀 快速开始

### 前置要求

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- XcodeGen (`brew install xcodegen`)
- **Node.js 20+**（用于后端服务器，本地模式下可选）

### 构建应用

```bash
cd demo-apps/iOS/MyPal

# 从 project.yml 生成 Xcode 项目
make generate

# 在 Xcode 中打开
make open

# 或直接构建和运行
make run
```

### 依赖项

应用使用 Swift Package Manager：
- **ChatKit**：`https://github.com/Geeksfino/finclip-chatkit.git`（v0.7.4）
- **MLX-Swift**：`https://github.com/ml-explore/mlx-swift`（用于本地 LLM）

## 📱 使用应用

### 首次启动

1. 应用启动时抽屉处于关闭状态
2. 点击菜单按钮打开抽屉
3. 点击 "+" 创建新对话
4. 聊天视图自动打开

### 切换模式

1. 使用顶部栏中的模式切换开关
2. **远程模式**：连接到后端服务器（需要服务器运行）
3. **本地模式**：在设备上使用 Gemma 270M（首次使用时下载模型）

### 创建对话

1. 点击抽屉中的 **"+"** 按钮
2. **聊天视图**打开，显示空对话
3. 输入消息并按发送
4. 代理响应（根据模式来自服务器或本地 LLM）

## 🏗️ 架构

```
MyPal/
├── App/
│   ├── App/
│   │   ├── SceneDelegate.swift            # 初始化 ChatKitCoordinator
│   │   ├── AppConfig.swift                # 应用配置（模式、模型设置）
│   │   ├── ComposerToolsExample.swift     # 撰写工具演示
│   │   └── LocalizationHelper.swift      # 国际化工具
│   ├── Network/                           # 新增
│   │   ├── LocalLLMURLProtocol.swift      # 拦截请求，路由到 MLX
│   │   └── LocalLLMAGUIEvents.swift       # 从 LLM 生成 AG-UI 事件
│   ├── Adapters/                          # 新增
│   │   ├── LocalLLMModelManager.swift     # MLX 模型加载/管理
│   │   └── ModelDownloader.swift          # 从 Hugging Face 下载模型
│   ├── Extensions/
│   │   ├── ChatContextProviders.swift    # 提供者工厂
│   │   ├── CalendarContextProvider.swift  # 日历上下文提供者
│   │   └── LocationContextProvider.swift   # 位置上下文提供者
│   └── ViewControllers/
│       ├── DrawerContainerViewController.swift
│       ├── DrawerViewController.swift
│       ├── MainChatViewController.swift   # 已修改（模式切换）
│       └── ChatViewController.swift
├── project.yml                            # XcodeGen 配置
└── Makefile                               # 构建自动化
```

## 🔧 配置

### 连接模式

在 `AppConfig.swift` 中：
```swift
enum ConnectionMode {
    case remote
    case local
}

static var currentMode: ConnectionMode = .remote
```

### 模型配置

```swift
// Gemma 270M 模型设置
static let modelName = "gemma-270m"
static let modelRepository = "mlx-community/gemma-270m-it"
```

## 📚 学习资源

### 文档

- **[Simple 演示](../Simple)** - 此应用扩展的基础演示
- **[MyChatGPT 示例](../../../chatkit/Examples/MyChatGPT)** - URLProtocol 模式参考
- **[快速入门指南](../../docs/quick-start.md)** - 最小化骨架代码
- **[API 级别指南](../../docs/api-levels.md)** - 高级 vs 低级 API

## 🐛 故障排除

### 构建错误

**"XcodeGen not found"**
- 安装：`brew install xcodegen`

**"Module 'ChatKit' not found"**
- 运行 `make generate` 重新生成项目
- 检查 `project.yml` 中是否有正确的包依赖

**"Module 'MLX' not found"**
- 确保 mlx-swift 包已添加到 project.yml
- 运行 `make generate` 更新依赖项

### 运行时错误

**"Failed to load local model"**
- 检查模型下载是否成功完成
- 验证是否有足够的存储空间
- 检查模型文件完整性

**"Model inference too slow"**
- Gemma 270M 已针对速度进行优化，但首次推理可能较慢
- 考虑使用远程模式以获得更快的响应

## 🤝 贡献

发现问题或想要添加功能？请参阅 [CONTRIBUTING.md](../../../CONTRIBUTING.md) 了解指南。

## 📄 许可证

MIT 许可证 - 详见 [LICENSE](../../../LICENSE)

---

**由 FinClip 团队用 ❤️ 制作**
