# ChatKit 文档

使用 FinClip ChatKit 构建 AI 驱动的聊天应用的完整文档。

---

## 🚀 快速导航

### 选择您的语言

**Swift 开发者?** → [Swift 快速开始](./getting-started.zh.md#swift) → [Swift 开发者指南](./guides/developer-guide.zh.md)

**Objective-C 开发者?** → [Objective-C 快速开始](./getting-started.zh.md#objective-c) → [Objective-C 开发者指南](./guides/objective-c-guide.zh.md)

---

## 📚 文档结构

### 概览与入门
- **[概览](./overview.zh.md)** - ChatKit 完整介绍：功能、协议和特性
- **[入门指南](./getting-started.zh.md)** - 特定语言的快速开始（Swift 和 Objective-C）
- **[快速开始指南](./quick-start.zh.md)** - 最小化骨架模板（5 分钟）

### 核心指南

#### Swift
- **[Swift 开发者指南](./guides/developer-guide.zh.md)** - 从初学者到专家的全面 Swift 指南
  - 基础用法
  - 多会话管理
  - 会话列表 UI
  - 高级模式

#### Objective-C
- **[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)** - 完整的 Objective-C 指南
  - 基础用法
  - 多会话管理
  - 会话列表 UI
  - API 参考

#### 共享概念
- **[配置指南](./guides/configuration.zh.md)** - 所有 ChatKit 选项的完整配置参考
- **[API 层级指南](./api-levels.zh.md)** - 理解高级 API 与低级 API
- **[组件嵌入指南](./component-embedding.zh.md)** - 在各种场景中嵌入组件（Swift 和 Objective-C 示例）
- **[上下文提供器指南](./guides/context-providers.zh.md)** - 实现自定义上下文提供器（Swift 和 Objective-C）
- **[提示启动器指南](./guides/prompt-starters.zh.md)** - 创建和配置提示启动器（Swift 和 Objective-C）
- **[提供者自定义](./api-levels.zh.md#provider-mechanism)** - 上下文、ASR 和标题生成提供者

### 集成与设置
- **[安装指南](./integration-guide.zh.md)** - 包管理器设置（SPM、CocoaPods）
- **[构建工具指南](./build-tooling.zh.md)** - Makefile、XcodeGen、可重现构建
- **[远程依赖](./remote-dependencies.zh.md)** - 使用远程二进制依赖

### 自定义
- **[UI 自定义](./how-to/customize-ui.zh.md)** - 样式和主题
- **[提供者机制](./api-levels.zh.md#provider-mechanism)** - 自定义框架行为

### 参考
- **[架构概述](./architecture/overview.zh.md)** - 框架结构和设计
- **[故障排除指南](./troubleshooting.zh.md)** - 常见问题和解决方案

---

## 🎯 学习路径

### Swift 开发者

0. **可选：了解 ChatKit** → [概览](./overview.zh.md) - 了解功能、协议和特性

1. **从这里开始**: [Swift 快速开始](./getting-started.zh.md#swift)
   - 5 分钟设置
   - 最小化代码示例

2. **学习基础**: [Swift 开发者指南 - 第 1 部分](./guides/developer-guide.zh.md#part-1-getting-started)
   - 详细演示
   - 关键概念

3. **构建功能**: [Swift 开发者指南 - 第 2 和 3 部分](./guides/developer-guide.zh.md)
   - 多会话管理
   - 会话历史

4. **自定义**: [组件嵌入](./component-embedding.zh.md) | [提供者](./api-levels.zh.md#provider-mechanism)

5. **高级**: [API 层级](./api-levels.zh.md) | [架构](./architecture/overview.zh.md)

### Objective-C 开发者

0. **可选：了解 ChatKit** → [概览](./overview.zh.md) - 了解功能、协议和特性

1. **从这里开始**: [Objective-C 快速开始](./getting-started.zh.md#objective-c)
   - 5 分钟设置
   - 最小化代码示例

2. **学习基础**: [Objective-C 开发者指南 - 基础用法](./guides/objective-c-guide.zh.md#basic-usage)
   - 协调器设置
   - 创建会话
   - 显示聊天 UI

3. **构建功能**: [Objective-C 开发者指南 - 多会话管理](./guides/objective-c-guide.zh.md#multiple-conversations)
   - 会话管理器
   - 观察更新
   - 恢复会话

4. **自定义**: [组件嵌入](./component-embedding.zh.md) | [提供者自定义](./guides/objective-c-guide.zh.md#provider-customization)

5. **参考**: [Objective-C API 参考](./guides/objective-c-guide.zh.md#api-reference)

---

## 📖 用例导航

### 我想要...

#### 了解 ChatKit 及其功能
- **[概览](./overview.zh.md)** - 完整介绍：功能、协议、特性和您可以构建的内容

#### 构建简单的聊天应用
- **Swift**: [快速开始](./getting-started.zh.md#swift) → [Swift 指南](./guides/developer-guide.zh.md)
- **Objective-C**: [快速开始](./getting-started.zh.md#objective-c) → [Objective-C 指南](./guides/objective-c-guide.zh.md)

#### 添加多会话功能
- **Swift**: [开发者指南 - 第 2 部分](./guides/developer-guide.zh.md#part-2-managing-multiple-conversations)
- **Objective-C**: [Objective-C 指南 - 多会话管理](./guides/objective-c-guide.zh.md#multiple-conversations)

#### 显示会话历史
- **Swift**: [开发者指南 - 第 3 部分](./guides/developer-guide.zh.md#part-3-building-a-conversation-list-ui)
- **Objective-C**: [Objective-C 指南 - 会话列表 UI](./guides/objective-c-guide.zh.md#conversation-list-ui)

#### 在抽屉中嵌入聊天
- [组件嵌入 - 抽屉](./component-embedding.zh.md#drawersidebar-container)（Swift 和 Objective-C 示例）

#### 以弹出层方式展示聊天
- [组件嵌入 - 弹出层](./component-embedding.zh.md#modal-sheet-presentation)（Swift 和 Objective-C 示例）

#### 使用 Objective-C
- [Objective-C 快速开始](./getting-started.zh.md#objective-c)
- [Objective-C 开发者指南](./guides/objective-c-guide.zh.md)
- [SimpleObjC 示例](../../demo-apps/iOS/SimpleObjC/)

#### 自定义会话标题
- **Swift**: [API 层级 - 标题提供者](./api-levels.zh.md#title-generation-providers)
- **Objective-C**: [Objective-C 指南 - 标题提供者](./guides/objective-c-guide.zh.md#title-generation-providers)

#### 添加位置上下文或自定义上下文提供器
- **Swift 和 Objective-C**: [上下文提供器指南](./guides/context-providers.zh.md) - 包含示例的完整指南
- **Swift**: [API 层级 - 上下文提供者](./api-levels.zh.md#context-providers)
- **Objective-C**: [Objective-C 指南 - 上下文提供者](./guides/objective-c-guide.zh.md#context-providers)

#### 配置聊天 UI 行为和外观
- **Swift 和 Objective-C**: [配置指南](./guides/configuration.zh.md) - 完整的配置参考
- 状态横幅、欢迎消息、提示启动器、工具、上下文提供器
- 主题自定义、性能调优、调试设置

#### 设置自动化构建
- [构建工具指南](./build-tooling.zh.md)

#### 故障排查
- [故障排除指南](./troubleshooting.zh.md)

---

## 🧪 示例应用

### Simple（Swift）
**位置**: `demo-apps/iOS/Simple/`

**演示内容**:
- 高级 API
- 基于抽屉的导航
- 组件嵌入
- 标准构建工具

**运行它**:
```bash
cd demo-apps/iOS/Simple
make run
```

**参见**: [Simple README](../../demo-apps/iOS/Simple/README.md)

### SimpleObjC（Objective-C）
**位置**: `demo-apps/iOS/SimpleObjC/`

**演示内容**:
- Objective-C 高级 API
- 基于导航的流程
- 远程依赖使用

**运行它**:
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**参见**: [SimpleObjC README](../../demo-apps/iOS/SimpleObjC/README.md)

---

## 📁 文档结构

```
docs/
├── README.zh.md（本文件）          # 主要文档索引
├── overview.zh.md                  # 高级概览和介绍
│
├── 入门指南
│   ├── getting-started.zh.md       # 详细演练（Swift 和 Objective-C）
│   └── quick-start.zh.md           # 最小化骨架模板（5 分钟）
│
├── guides/                         # 特定语言的全面指南
│   ├── developer-guide.zh.md       # Swift 全面指南
│   ├── objective-c-guide.zh.md    # Objective-C 全面指南
│   ├── configuration.zh.md         # 配置指南（Swift 和 Objective-C）
│   ├── context-providers.zh.md      # 上下文提供器指南（Swift 和 Objective-C）
│   └── prompt-starters.zh.md       # 提示启动器指南（Swift 和 Objective-C）
│
├── 核心概念                        # 共享概念（Swift 和 Objective-C）
│   ├── api-levels.zh.md            # 高级 API 与低级 API
│   └── component-embedding.zh.md   # 组件使用场景
│
├── 集成与设置
│   ├── integration-guide.zh.md     # 包管理器、安装
│   ├── build-tooling.zh.md         # Makefile、XcodeGen
│   ├── remote-dependencies.zh.md  # 远程二进制依赖
│   └── running-demos.zh.md         # 运行演示应用
│
├── 自定义
│   └── how-to/
│       └── customize-ui.zh.md     # UI 自定义
│
├── 参考
│   ├── architecture/
│   │   └── overview.zh.md          # 框架架构
│   └── troubleshooting.zh.md      # 常见问题和解决方案
│
└── archive/                        # 历史/维护者文档
    ├── summaries/                  # 历史摘要
    ├── llmtxt/                     # 遗留内容
    ├── STRUCTURE.zh.md             # 文档结构（供维护者使用）
    ├── RESTRUCTURING_SUMMARY.zh.md # 重构摘要（供维护者使用）
    └── TRANSLATION_STATUS.zh.md    # 翻译状态（供维护者使用）
```

---

## 🔑 关键概念

### 高级 API（推荐）
处理大多数用例的现成组件：
- `ChatKitCoordinator` / `CKTChatKitCoordinator` - 运行时生命周期
- `ChatKitConversationViewController` - 聊天 UI（Swift 和 Objective-C）
- `ChatKitConversationListViewController` - 列表 UI（Swift 和 Objective-C）

**参见**: [API 层级指南](./api-levels.zh.md#high-level-apis-recommended)

### 低级 API（高级）
直接访问以获得最大灵活性：
- 直接运行时访问
- 手动 UI 绑定
- 自定义实现

**参见**: [API 层级指南](./api-levels.zh.md#low-level-apis-advanced)

### 提供者机制
自定义框架行为：
- 上下文提供者 - 附加位置、日历等
- ASR 提供者 - 自定义语音识别
- 标题生成提供者 - 自定义会话标题

**参见**: [API 层级指南](./api-levels.zh.md#provider-mechanism)

---

## 🌐 语言支持

### Swift
- ✅ 完整的 API 支持
- ✅ Async/await 模式
- ✅ Combine 发布者
- ✅ 类型安全的 API

**指南**: [Swift 开发者指南](./guides/developer-guide.zh.md)

### Objective-C
- ✅ 通过包装器完整支持 API
- ✅ 基于委托的模式
- ✅ 完成处理器
- ✅ `CKT` 前缀类

**指南**: [Objective-C 开发者指南](./guides/objective-c-guide.zh.md)

---

## 📋 版本信息

本文档适用于 **ChatKit 0.7.4**。

所有示例和代码片段使用 0.7.4 或更高版本中可用的 API。

---

## 🤝 贡献

发现问题或想改进文档？

1. 打开一个 issue 描述问题或改进建议
2. 提交包含您更改的 pull request
3. 遵循现有的文档风格和结构

---

## 🆘 支持

- **文档问题**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
- **问题咨询**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)
- **示例**: `demo-apps/iOS/` 目录

---

## 🎓 您将学到什么

通过示例和文档：

- ✅ 用于快速开发的高级 API（Swift 和 Objective-C）
- ✅ 安全的运行时生命周期管理
- ✅ 现成的 UI 组件
- ✅ 在各种容器中嵌入组件
- ✅ 管理多个会话
- ✅ 提供者机制（上下文、ASR、标题生成）
- ✅ 使用 Makefile 和 XcodeGen 的可重现构建
- ✅ 最佳实践和常见陷阱

---

**准备好开始构建了吗？**

- **Swift 开发者?** → [Swift 快速开始](./getting-started.zh.md#swift)
- **Objective-C 开发者?** → [Objective-C 快速开始](./getting-started.zh.md#objective-c)

---

Made with ❤️ by the FinClip team
