<div align="center">
  <img src="assets/FinClip ChatKit Banner 1200x300.png" alt="FinClip ChatKit" width="100%">
</div>

# FinClip ChatKit

> **Stop building chat UIs from scratch.**
> The complete toolkit for building native AI-powered chat applications on mobile apps.

[简体中文](README.zh.md) | [English](README.md)

Building the intelligence for your AI agent is hard enough. Don't waste weeks fighting with list views, keyboard handling, and message bubbles. ChatKit gives you a **production-ready chat interface** that feels 100% native, right out of the box.

<div align="center">
  <img src="assets/chatkit-beyond-text-hero.png" width="100%">
</div>

---

## 🚀 Get Started in 5 Minutes

We know you want to see code running. Choose your path:

### 🍎 For iOS Developers
* **Swift?** → [**Jump to Swift Quick Start**](docs/getting-started.md#swift-quick-start) (The modern way) | [Minimal Skeleton](docs/quick-start.md#swift-quick-start)
* **Objective-C?** → [**Jump to Obj-C Quick Start**](docs/getting-started.md#objective-c-quick-start) (Legacy codebase? We got you.) | [Minimal Skeleton](docs/quick-start.md#objective-c-quick-start)

### 🤖 For Android Developers
* **Kotlin/Java?** → [**Android Examples**](https://github.com/Geeksfino/finclip-chatkit/tree/main/demo-apps/Android) | [README](demo-apps/Android/README.md)

---

## 🏗 What Can You Build?

ChatKit is designed to scale from simple embedded widgets to full-blown AI assistants.

<div align="center">
  <img src="assets/from-components-to-solutions.png" width="100%">
</div>

### 1. Embedded Context-Aware Copilots
Don't force users to leave their current task to get help. Embed ChatKit as a **mini-program overlay** or a **floating entry** directly within your existing workflows (e.g., stock charts, dashboards).
* **Context Injection**: Automatically pass the current screen's data to the LLM. The agent "sees" what the user sees. [Learn more](docs/guides/context-providers.md)
* **Non-intrusive**: Users summon the agent for specific tasks and dismiss it immediately. [Component Embedding Guide](docs/component-embedding.md)

### 2. Vertical Expert Agents
Build independent, professional-grade AI assistants (like *Project Samantha*) capable of handling complex domain logic.
* **Generative UI**: Render complex financial tables, forms, or interactive charts dynamically using **MCP-UI** or **AG-UI** protocols. [Protocol Support](docs/overview.md#-protocol--convention-support)
* **One-Shot Execution**: Turn natural language (e.g., "Buy 100 shares of AAPL") into secure, sandboxed actions immediately—bypassing deep menus. [Architecture Overview](docs/architecture/overview.md)

### 3. Hybrid Human-AI Workflows
Don't leave users stranded when the AI hits a limit.
* **Seamless Handoff**: Automatically route high-stakes or complex intent to human agents without losing conversation context.
* **Huddle Mode**: Enable a unique **three-way collaboration** (User + AI + Human) where the AI acts as a copilot for the human advisor.

---

## 💡 Why ChatKit?

**Context is King.** Generic chatbots fail because they don't know who the user is. ChatKit connects the dots.

<div align="center">
  <img src="assets/no-friction-way-to-intelligence.jpg" alt="Context Aware vs Generic" width="100%">
</div>

* **Frictionless**: No need to ask "Where are you?". The SDK already knows. [Context Providers Guide](docs/guides/context-providers.md)
* **Proactive**: Trigger actions based on location, time, or battery status. [Overview](docs/overview.md#-context-aware-intelligence)

---

## 💡 Why Developers Love ChatKit

We fit your workflow, whether you need speed or control.

🏎️ **Ship Fast (High-Level APIs)**: Need a chat screen now? Components like `ChatKitConversationViewController` handle lifecycle and UI rendering for you. [Read Guide](docs/api-levels.md#high-level-apis-recommended)

🛠️ **Full Control (Low-Level APIs)**: Need custom layouts? Drop down to direct runtime access and manual UI binding. [Read Guide](docs/api-levels.md#low-level-apis-advanced)

🧩 **Make It Yours (Providers)**: Inject Location, Calendar events, or custom data directly into the LLM context. [Context Providers Guide](docs/guides/context-providers.md)

---

## 🧪 Example Apps

Clone the repo and run these demos to see ChatKit in action.

**📖 For complete instructions**: See [Running Demos](docs/running-demos.md) for detailed setup and troubleshooting.

### Simple (Swift)
**Location**: `demo-apps/iOS/Simple/`  
Demonstrates high-level APIs, drawer navigation, and standard build tooling.

```bash
cd demo-apps/iOS/Simple
make run
```

**See**: [Simple README](demo-apps/iOS/Simple/README.md)

### SimpleObjC (Objective-C)
**Location**: `demo-apps/iOS/SimpleObjC/`  
Demonstrates Objective-C integration and legacy support.

```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**See**: [SimpleObjC README](demo-apps/iOS/SimpleObjC/README.md)

### Android Examples
**Location**: `demo-apps/Android/`  
A complete demo app with multiple scenarios.

```bash
cd demo-apps/Android
make run
```

**See**: [Android Examples](https://github.com/Geeksfino/finclip-chatkit/tree/main/demo-apps/Android) | [README](demo-apps/Android/README.md) | [中文](demo-apps/Android/README_CN.md)

---

## 📚 Documentation Index

### Overview & Getting Started
* **[Overview](docs/overview.md)** - Complete introduction to ChatKit: features, protocols, and capabilities
* **[Getting Started](docs/getting-started.md)** - Language-specific quick starts (Swift & Objective-C)
* **[Quick Start](docs/quick-start.md)** - Minimal skeleton code (5 minutes)

### Core Guides
* **[Swift Developer Guide](docs/guides/developer-guide.md)** - From basic usage to advanced patterns.
* **[Objective-C Developer Guide](docs/guides/objective-c-guide.md)** - Complete API reference for Obj-C.
* **[Configuration Guide](docs/guides/configuration.md)** - Customize everything: themes, prompt starters, debug settings.

### Advanced Concepts
* **[Context Providers](docs/guides/context-providers.md)** - How to inject custom data into conversations.
* **[Component Embedding](docs/component-embedding.md)** - Embed chat in Drawers, Sheets, or Tabs.
* **[Prompt Starters](docs/guides/prompt-starters.md)** - Configure welcome chips and initial suggestions.

### Setup & Tools
* **[Installation Guide](docs/integration-guide.md)** - SPM, CocoaPods setup.
* **[Build Tooling](docs/build-tooling.md)** - Makefile & XcodeGen guide.
* **[Troubleshooting](docs/troubleshooting.md)** - Solutions for common issues.

➡️ **Full index**: [docs/README.md](docs/README.md)

---

## 🤝 Contributing & Support

* **Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
* **Discussions**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)

---

Made with ❤️ by the FinClip team
