# ChatKit Documentation

Complete documentation for building AI-powered chat applications with FinClip ChatKit.

---

## 🚀 Quick Navigation

### Choose Your Language

**Swift Developer?** → [Swift Quick Start](./getting-started.md#swift) → [Swift Developer Guide](./guides/developer-guide.md)

**Objective-C Developer?** → [Objective-C Quick Start](./getting-started.md#objective-c) → [Objective-C Developer Guide](./guides/objective-c-guide.md)

---

## 📚 Documentation Structure

### Getting Started
- **[Getting Started Guide](./getting-started.md)** - Language-specific quick starts (Swift & Objective-C)
- **[Quick Start Guide](./quick-start.md)** - Minimal skeleton templates (5 minutes)

### Core Guides

#### Swift
- **[Swift Developer Guide](./guides/developer-guide.md)** - Comprehensive Swift guide from beginner to expert
  - Basic usage
  - Multiple conversations
  - Conversation list UI
  - Advanced patterns

#### Objective-C
- **[Objective-C Developer Guide](./guides/objective-c-guide.md)** - Complete Objective-C guide
  - Basic usage
  - Multiple conversations
  - Conversation list UI
  - API reference

#### Shared Concepts
- **[API Levels Guide](./api-levels.md)** - Understanding high-level vs low-level APIs
- **[Component Embedding Guide](./component-embedding.md)** - Embedding components in various scenarios (Swift & Objective-C examples)
- **[Context Providers Guide](./guides/context-providers.md)** - Implementing custom context providers (Swift & Objective-C)
- **[Prompt Starters Guide](./guides/prompt-starters.md)** - Creating and configuring prompt starters (Swift & Objective-C)
- **[Provider Customization](./api-levels.md#provider-mechanism)** - Context, ASR, and title generation providers

### Integration & Setup
- **[Installation Guide](./integration-guide.md)** - Package manager setup (SPM, CocoaPods)
- **[Build Tooling Guide](./build-tooling.md)** - Makefile, XcodeGen, reproducible builds
- **[Remote Dependencies](./remote-dependencies.md)** - Working with remote binary dependencies

### Customization
- **[UI Customization](./how-to/customize-ui.md)** - Styling and theming
- **[Provider Mechanisms](./api-levels.md#provider-mechanism)** - Customize framework behavior

### Reference
- **[Architecture Overview](./architecture/overview.md)** - Framework structure and design
- **[Troubleshooting Guide](./troubleshooting.md)** - Common issues and solutions

---

## 🎯 Learning Paths

### For Swift Developers

1. **Start Here**: [Swift Quick Start](./getting-started.md#swift)
   - 5-minute setup
   - Minimal code example

2. **Learn Basics**: [Swift Developer Guide - Part 1](./guides/developer-guide.md#part-1-getting-started)
   - Detailed walkthrough
   - Key concepts

3. **Build Features**: [Swift Developer Guide - Parts 2 & 3](./guides/developer-guide.md)
   - Multiple conversations
   - Conversation history

4. **Customize**: [Component Embedding](./component-embedding.md) | [Providers](./api-levels.md#provider-mechanism)

5. **Advanced**: [API Levels](./api-levels.md) | [Architecture](./architecture/overview.md)

### For Objective-C Developers

1. **Start Here**: [Objective-C Quick Start](./getting-started.md#objective-c)
   - 5-minute setup
   - Minimal code example

2. **Learn Basics**: [Objective-C Developer Guide - Basic Usage](./guides/objective-c-guide.md#basic-usage)
   - Coordinator setup
   - Creating conversations
   - Showing chat UI

3. **Build Features**: [Objective-C Developer Guide - Multiple Conversations](./guides/objective-c-guide.md#multiple-conversations)
   - Conversation manager
   - Observing updates
   - Resuming conversations

4. **Customize**: [Component Embedding](./component-embedding.md) | [Provider Customization](./guides/objective-c-guide.md#provider-customization)

5. **Reference**: [Objective-C API Reference](./guides/objective-c-guide.md#api-reference)

---

## 📖 Use Case Navigation

### I want to...

#### Build a simple chat app
- **Swift**: [Quick Start](./getting-started.md#swift) → [Swift Guide](./guides/developer-guide.md)
- **Objective-C**: [Quick Start](./getting-started.md#objective-c) → [Objective-C Guide](./guides/objective-c-guide.md)

#### Add multiple conversations
- **Swift**: [Developer Guide - Part 2](./guides/developer-guide.md#part-2-managing-multiple-conversations)
- **Objective-C**: [Objective-C Guide - Multiple Conversations](./guides/objective-c-guide.md#multiple-conversations)

#### Show conversation history
- **Swift**: [Developer Guide - Part 3](./guides/developer-guide.md#part-3-building-a-conversation-list-ui)
- **Objective-C**: [Objective-C Guide - Conversation List UI](./guides/objective-c-guide.md#conversation-list-ui)

#### Embed chat in a drawer
- [Component Embedding - Drawer](./component-embedding.md#drawersidebar-container) (Swift & Objective-C examples)

#### Present chat as a sheet
- [Component Embedding - Sheet](./component-embedding.md#modal-sheet-presentation) (Swift & Objective-C examples)

#### Use Objective-C
- [Objective-C Quick Start](./getting-started.md#objective-c)
- [Objective-C Developer Guide](./guides/objective-c-guide.md)
- [SimpleObjC Demo](../../demo-apps/iOS/SimpleObjC/)

#### Customize conversation titles
- **Swift**: [API Levels - Title Providers](./api-levels.md#title-generation-providers)
- **Objective-C**: [Objective-C Guide - Title Providers](./guides/objective-c-guide.md#title-generation-providers)

#### Add location context or custom context providers
- **Swift & Objective-C**: [Context Providers Guide](./guides/context-providers.md) - Complete guide with examples
- **Swift**: [API Levels - Context Providers](./api-levels.md#context-providers)
- **Objective-C**: [Objective-C Guide - Context Providers](./guides/objective-c-guide.md#context-providers)

#### Set up automated builds
- [Build Tooling Guide](./build-tooling.md)

#### Troubleshoot issues
- [Troubleshooting Guide](./troubleshooting.md)

---

## 🧪 Example Apps

### Simple (Swift)
**Location**: `demo-apps/iOS/Simple/`

**What it demonstrates**:
- High-level APIs
- Drawer-based navigation
- Component embedding
- Standard build tooling

**Run it**:
```bash
cd demo-apps/iOS/Simple
make run
```

**See**: [Simple README](../../demo-apps/iOS/Simple/README.md)

### SimpleObjC (Objective-C)
**Location**: `demo-apps/iOS/SimpleObjC/`

**What it demonstrates**:
- Objective-C high-level APIs
- Navigation-based flow
- Remote dependency usage

**Run it**:
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

**See**: [SimpleObjC README](../../demo-apps/iOS/SimpleObjC/README.md)

---

## 📁 Documentation Structure

```
docs/
├── README.md (this file)
│
├── Getting Started
│   ├── getting-started.md          # Language-specific quick starts
│   └── quick-start.md              # Minimal skeleton templates
│
├── guides/
│   ├── developer-guide.md          # Swift comprehensive guide
│   ├── objective-c-guide.md         # Objective-C comprehensive guide
│   ├── context-providers.md         # Context providers guide (Swift & Objective-C)
│   ├── context-providers.zh.md      # Context providers guide (Chinese)
│   ├── prompt-starters.md          # Prompt starters guide (Swift & Objective-C)
│   └── prompt-starters.zh.md       # Prompt starters guide (Chinese)
│
├── Core Concepts
│   ├── api-levels.md               # High-level vs low-level APIs
│   └── component-embedding.md      # Component usage scenarios
│
├── integration/
│   ├── integration-guide.md        # Package managers, installation
│   ├── build-tooling.md           # Makefile, XcodeGen
│   └── remote-dependencies.md      # Remote binary dependencies
│
├── customization/
│   └── how-to/
│       └── customize-ui.md         # UI customization
│
├── reference/
│   ├── architecture/
│   │   └── overview.md             # Framework architecture
│   └── troubleshooting.md          # Common issues
│
└── (legacy files - to be consolidated)
```

---

## 🔑 Key Concepts

### High-Level APIs (Recommended)
Ready-made components that handle most use cases:
- `ChatKitCoordinator` / `CKTChatKitCoordinator` - Runtime lifecycle
- `ChatKitConversationViewController` - Chat UI (Swift & Objective-C)
- `ChatKitConversationListViewController` - List UI (Swift & Objective-C)

**See**: [API Levels Guide](./api-levels.md#high-level-apis-recommended)

### Low-Level APIs (Advanced)
Direct access for maximum flexibility:
- Direct runtime access
- Manual UI binding
- Custom implementations

**See**: [API Levels Guide](./api-levels.md#low-level-apis-advanced)

### Provider Mechanism
Customize framework behavior:
- Context providers - Attach location, calendar, notes, etc.
- ASR providers - Custom speech recognition
- Title generation providers - Custom conversation titles

**See**: [Context Providers Guide](./guides/context-providers.md) | [API Levels Guide](./api-levels.md#provider-mechanism)

---

## 🌐 Language Support

### Swift
- ✅ Full API support
- ✅ Async/await patterns
- ✅ Combine publishers
- ✅ Type-safe APIs

**Guides**: [Swift Developer Guide](./guides/developer-guide.md)

### Objective-C
- ✅ Full API support via wrappers
- ✅ Delegate-based patterns
- ✅ Completion handlers
- ✅ `CKT`-prefixed classes

**Guides**: [Objective-C Developer Guide](./guides/objective-c-guide.md)

---

## 📋 Version Information

This documentation is for **ChatKit 0.7.4**.

All examples and code snippets use APIs available in version 0.7.4 or later.

---

## 🤝 Contributing

Found an issue or want to improve the documentation?

1. Open an issue describing the problem or improvement
2. Submit a pull request with your changes
3. Follow the existing documentation style and structure

---

## 🆘 Support

- **Documentation Issues**: [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
- **Questions**: [GitHub Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)
- **Examples**: `demo-apps/iOS/` directory

---

## 🎓 What You'll Learn

From the examples and documentation:

- ✅ High-level APIs for rapid development (Swift & Objective-C)
- ✅ Safe runtime lifecycle management
- ✅ Ready-made UI components
- ✅ Component embedding in various containers
- ✅ Managing multiple conversations
- ✅ Provider mechanisms (context, ASR, title generation)
- ✅ Reproducible builds with Makefile and XcodeGen
- ✅ Best practices and common pitfalls

---

**Ready to build?**

- **Swift Developer?** → [Swift Quick Start](./getting-started.md#swift)
- **Objective-C Developer?** → [Objective-C Quick Start](./getting-started.md#objective-c)

---

Made with ❤️ by the FinClip team
