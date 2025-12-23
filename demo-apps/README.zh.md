<div align="center">
  <img src="assets/FinClip ChatKit Banner 1200x300.png" alt="FinClip ChatKit" width="100%">
</div>

# FinClip ChatKit

> **别再从头手撸聊天界面了。**
> 专为移动应用打造的原生 AI 聊天应用开发套件。

[简体中文](README.zh.md) | [English](README.md)

搞定 AI 的核心逻辑已经够累了，就别再跟列表视图、键盘高度和气泡渲染较劲了。ChatKit 为您提供了一套**生产级、开箱即用**的原生聊天界面，让您的 AI 应用像系统原生 App 一样丝滑。

<div align="center">
  <img src="assets/chatkit-beyond-text-hero.png" width="100%">
</div>

---

## 🚀 5 分钟快速上手

我们知道您想直接看代码跑起来。请选择您的开发语言：

### 🍎 iOS 开发者
* **Swift?** → [**传送门：Swift 快速开始**](docs/getting-started.zh.md#swift-quick-start)（推荐）
* **Objective-C?** → [**传送门：Obj-C 快速开始**](docs/getting-started.zh.md#objective-c-quick-start)（老项目也没问题，我们全支持）

### 🤖 Android 开发者
* **Kotlin/Java?** → [**Android 示例**](https://github.com/Geeksfino/finclip-chatkit/tree/main/demo-apps/Android) | [README](demo-apps/Android/README.md) | [中文](demo-apps/Android/README_CN.md)

---

## 🏗 您可以构建什么？

ChatKit 的设计初衷是灵活适应从"轻量级嵌入"到"全功能助理"的各种需求。

<div align="center">
  <img src="assets/from-components-to-solutions.png" width="100%">
</div>

### 1. 嵌入式 AI Copilot
不要让用户跳出当前业务流。您可以将 ChatKit 作为**小程序浮层**或**悬浮入口**，无缝嵌入到 K 线图、文档阅读器或任何原生页面中。
* **上下文注入 (Context Injection)**：自动将当前屏幕的信息"喂"给 AI，让 AI 真正"看懂"用户当前在做什么。
* **即用即走**：用户在需要时唤起，解决问题后立即返回主任务，体验无中断。

### 2. 垂直领域专家 Agent
打造像 *Project Samantha* 这样不仅能聊天，还能干活的专家级助理。
* **生成式 UI (Generative UI)**：通过 **MCP-UI** 或 **AG-UI** 协议，让 AI 动态生成复杂的交易面板、表单或图表，而非仅仅输出文本。
* **一语直达 (One-Shot Action)**：支持将自然语言指令（如"买入100股苹果"）直接转化为安全沙箱内的原子操作，实现从意图到执行的闭环。

### 3. 人机协同工作流
不要让 AI 的局限性成为服务的终点。
* **无缝接管**：在遇到高风险操作或复杂意图时，自动将对话路由给真人顾问，同时保留完整的上下文记忆。
* **三方会商**：支持独特的 **User + AI + Human** 协作模式，AI 不退场，而是转为辅助角色，实时为真人顾问提供数据摘要。

---

## 💡 为什么选择 ChatKit？

**上下文为王。** 通用聊天机器人失败的原因在于它们不知道用户是谁。ChatKit 连接了这些点。

<div align="center">
  <img src="assets/no-friction-way-to-intelligence.jpg" alt="上下文感知 vs 通用" width="100%">
</div>

* **无摩擦**：无需询问"您在哪里？"。SDK 已经知道。
* **主动式**：基于位置、时间或电池状态触发操作。

---

## 💡 为什么开发者喜欢 ChatKit？

无论您追求极速上线，还是极致定制，我们都能满足。

🏎️ **极速开发 (High-Level APIs)**：老板催着要 demo？像 `ChatKitConversationViewController` 这样的组件会帮你搞定生命周期和渲染。你只管业务，剩下的交给我们。[了解高级 API](docs/api-levels.zh.md#high-level-apis-recommended)

🛠️ **极致掌控 (Low-Level APIs)**：设计师有特殊需求？下潜到低级 API，直接访问运行时并手动绑定 UI。[了解低级 API](docs/api-levels.zh.md#low-level-apis-advanced)

🧩 **注入灵魂 (Providers)**：利用 Provider 机制，轻松将地理位置、日历事件注入到 LLM 上下文中，甚至随意替换 ASR 引擎。[上下文提供器指南](docs/guides/context-providers.zh.md)

---

## 🧪 示例应用

克隆仓库并运行这些 Demo，亲自体验 ChatKit。

### Simple (Swift)
**位置**: `demo-apps/iOS/Simple/`  
演示了高级 API、抽屉式导航和标准构建工具的使用。

```bash
cd demo-apps/iOS/Simple
make run
```

**参见**: [Simple README](demo-apps/iOS/Simple/README.md)

### SimpleObjC (Objective-C)
**位置**: `demo-apps/iOS/SimpleObjC/`  
演示了 Objective-C 集成和对老项目的支持。

```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**参见**: [SimpleObjC README](demo-apps/iOS/SimpleObjC/README.md)

### Android 示例
**位置**: `demo-apps/Android/`  
包含多个场景的完整演示应用。

```bash
cd demo-apps/Android
make run
```

**参见**: [Android 示例](https://github.com/Geeksfino/finclip-chatkit/tree/main/demo-apps/Android) | [README](demo-apps/Android/README.md) | [中文](demo-apps/Android/README_CN.md)

---

## 📚 文档索引

### 核心指南
* **[Swift 开发者指南](docs/guides/developer-guide.zh.md)** - 从入门到精通的完整指南。
* **[Objective-C 开发者指南](docs/guides/objective-c-guide.zh.md)** - 完整的 Obj-C API 参考。
* **[配置指南](docs/guides/configuration.zh.md)** - 自定义一切：主题、调试设置等。

### 进阶概念
* **[上下文提供器](docs/guides/context-providers.zh.md)** - 如何向对话注入自定义数据。
* **[组件嵌入指南](docs/component-embedding.md)** - 在侧边栏、弹窗或标签页中嵌入聊天。
* **[提示启动器](docs/guides/prompt-starters.zh.md)** - 配置欢迎语和快捷建议。

### 设置与工具
* **[安装指南](docs/integration-guide.zh.md)** - SPM、CocoaPods 安装说明。
* **[构建工具](docs/build-tooling.zh.md)** - Makefile 与 XcodeGen 使用指南。
* **[故障排除](docs/troubleshooting.zh.md)** - 常见问题解决方案。

➡️ **完整索引**: [docs/README.zh.md](docs/README.zh.md)

---

## 🤝 贡献与支持

* **提交 Issue**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
* **参与讨论**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)

---

Made with ❤️ by the FinClip team
