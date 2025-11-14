# MyPal Demo App

A demonstration app showcasing ChatKit with **local LLM support** using Google Gemma 270M via MLX-Swift. This app extends the Simple demo with offline AI capabilities.

> **📘 Key Feature: Local LLM Integration**  
>  
> This app demonstrates:
> - Local LLM inference using Google Gemma 270M via MLX-Swift
> - Seamless switching between online (remote server) and offline (local LLM) modes
> - URLProtocol interception pattern (like MyChatGPT's MockSSEURLProtocol)
> - Reusing existing AGUI_Adapter infrastructure

## 🎯 Overview

MyPal demonstrates:
- ✅ **Local LLM Support** - Google Gemma 270M running on-device via MLX-Swift
- ✅ **Dual Mode Operation** - Switch between remote server and local LLM
- ✅ **High-Level APIs** - Same ChatKit high-level APIs as Simple demo
- ✅ **Component Embedding** - Drawer-based navigation pattern
- ✅ **Persistent Storage** - Automatic conversation persistence
- ✅ **Build Tooling** - Reproducible builds with Makefile and XcodeGen

## 📦 Features

### 1. Local LLM Integration

**Gemma 270M via MLX-Swift:**
- On-device inference using Apple-optimized MLX framework
- Model downloaded on first local mode activation
- Seamless integration with existing ChatKit infrastructure

### 2. Mode Switching

**Remote vs Local:**
- Toggle between remote server and local LLM modes
- Same UI and conversation experience
- Automatic model download when switching to local mode

### 3. High-Level Component Usage

Same as Simple demo:
- `ChatKitCoordinator` - Runtime lifecycle management
- `ChatKitConversationViewController` - Ready-made chat UI
- `ChatKitConversationListViewController` - Ready-made list UI

## 🚀 Getting Started

### Prerequisites

- macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- XcodeGen (`brew install xcodegen`)
- **Node.js 20+** (for backend server, optional for local mode)

### Building the App

```bash
cd demo-apps/iOS/MyPal

# Generate Xcode project from project.yml
make generate

# Open in Xcode
make open

# Or build and run directly
make run
```

### Dependencies

The app uses Swift Package Manager:
- **ChatKit**: `https://github.com/Geeksfino/finclip-chatkit.git` (v0.6.1)
- **MLX-Swift**: `https://github.com/ml-explore/mlx-swift` (for local LLM)

## 📱 Using the App

### First Launch

1. App launches with drawer closed
2. Tap the menu button to open drawer
3. Tap "+" to create a new conversation
4. Chat view opens automatically

### Switching Modes

1. Use the mode toggle in the top bar
2. **Remote Mode**: Connects to backend server (requires server running)
3. **Local Mode**: Uses Gemma 270M on-device (downloads model on first use)

### Creating a Conversation

1. Tap **"+"** button in drawer
2. **Chat View** opens with empty conversation
3. Type a message and press send
4. Agent responds (from server or local LLM depending on mode)

## 🏗️ Architecture

```
MyPal/
├── App/
│   ├── App/
│   │   ├── SceneDelegate.swift            # Initialize ChatKitCoordinator
│   │   ├── AppConfig.swift                # App configuration (mode, model settings)
│   │   ├── ComposerToolsExample.swift     # Composer tools demo
│   │   └── LocalizationHelper.swift      # i18n utilities
│   ├── Network/                           # NEW
│   │   ├── LocalLLMURLProtocol.swift      # Intercepts requests, routes to MLX
│   │   └── LocalLLMAGUIEvents.swift       # Generates AG-UI events from LLM
│   ├── Adapters/                          # NEW
│   │   ├── LocalLLMModelManager.swift     # MLX model loading/management
│   │   └── ModelDownloader.swift          # Model download from Hugging Face
│   ├── Extensions/
│   │   ├── ChatContextProviders.swift    # Provider factory
│   │   ├── CalendarContextProvider.swift  # Calendar context provider
│   │   └── LocationContextProvider.swift   # Location context provider
│   └── ViewControllers/
│       ├── DrawerContainerViewController.swift
│       ├── DrawerViewController.swift
│       ├── MainChatViewController.swift   # MODIFIED (mode toggle)
│       └── ChatViewController.swift
├── project.yml                            # XcodeGen configuration
└── Makefile                               # Build automation
```

## 🔧 Configuration

### Connection Mode

In `AppConfig.swift`:
```swift
enum ConnectionMode {
    case remote
    case local
}

static var currentMode: ConnectionMode = .remote
```

### Model Configuration

```swift
// Gemma 270M model settings
static let modelName = "gemma-270m"
static let modelRepository = "mlx-community/gemma-270m-it"
```

## 📚 Learning Resources

### Documentation

- **[Simple Demo](../Simple)** - Base demo this app extends
- **[MyChatGPT Example](../../../chatkit/Examples/MyChatGPT)** - URLProtocol pattern reference
- **[Quick Start Guide](../../docs/quick-start.md)** - Minimal skeleton code
- **[API Levels Guide](../../docs/api-levels.md)** - High-level vs low-level APIs

## 🐛 Troubleshooting

### Build Errors

**"XcodeGen not found"**
- Install: `brew install xcodegen`

**"Module 'ChatKit' not found"**
- Run `make generate` to regenerate project
- Check `project.yml` has correct package dependency

**"Module 'MLX' not found"**
- Ensure mlx-swift package is added to project.yml
- Run `make generate` to update dependencies

### Runtime Errors

**"Failed to load local model"**
- Check model download completed successfully
- Verify sufficient storage space available
- Check model file integrity

**"Model inference too slow"**
- Gemma 270M is optimized for speed, but first inference may be slower
- Consider using remote mode for faster responses

## 🤝 Contributing

Found an issue or want to add features? See [CONTRIBUTING.md](../../../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - see [LICENSE](../../../LICENSE) for details

---

**Made with ❤️ by the FinClip team**

