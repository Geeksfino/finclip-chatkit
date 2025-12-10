# ChatKit Android Demo

This directory contains a comprehensive collection of example applications demonstrating how to use the ChatKit Android SDK. Each example focuses on different aspects and use cases of the SDK.

[中文文档](README_CN.md)

## 📋 Prerequisites

- Android Studio Hedgehog (2023.1.1) or later
- Android device or emulator (API 24+)
- GitHub Personal Access Token (for downloading SDK packages)
- Optional: A ChatKit backend server URL (or use Mock mode for offline testing)

## 🔑 GitHub Packages Authentication

The ChatKit SDK and its dependencies are hosted on GitHub Packages. You need to configure authentication before building.

### Option 1: Environment Variables (Recommended for CI/CD)

```bash
export GITHUB_USERNAME=wubingjie1st
export GITHUB_TOKEN=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
```

### Option 2: Gradle Properties (Recommended for Local Development)

Add to `~/.gradle/gradle.properties`:

```properties
gpr.user=wubingjie1st
gpr.key=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
```

## 🚀 Quick Start

### Prerequisites Check

Before starting, ensure:

1. **Android device or emulator is connected**
   ```bash
   # Check device connection
   adb devices
   # Should show connected devices, e.g.:
   # List of devices attached
   # emulator-5554    device
   ```

2. **GitHub Packages authentication is configured**
   - Option 1: Environment variables
     ```bash
     export GITHUB_USERNAME=wubingjie1st
     export GITHUB_TOKEN=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
     ```
   - Option 2: Gradle properties (`~/.gradle/gradle.properties`)
     ```properties
     gpr.user=wubingjie1st
     gpr.key=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
     ```

### Method 1: Using Makefile (Recommended)

The project includes a Makefile that simplifies common build, install, and run operations.

#### View All Available Commands

```bash
cd demo-apps/Android
make help
```

#### Common Commands

```bash
# Build, install, and launch in one command (most common)
make run

# Build APK only
make build

# Install app only (requires build first)
make install

# Launch app only (requires install first)
make start

# Stop running app
make stop

# Uninstall app
make uninstall

# Clean build files
make clean

# Build Release version
make release

# Check device connection status
make check-device

# View app logs
make logcat

# Run code linting
make lint

# Run unit tests
make test
```

#### Complete Workflow Example

```bash
# Navigate to project directory
cd demo-apps/Android

# Check device connection
make check-device

# Build, install, and launch (one command)
make run

# Or execute step by step
make build    # Build APK
make install  # Install to device
make start    # Launch app
```

### Method 2: Install and Launch via Command Line (Gradle)

#### Step 1: Navigate to Project Directory

```bash
cd demo-apps/Android
```

#### Step 2: Build the Project

```bash
# Build Debug APK
./gradlew assembleDebug

# After successful build, APK will be generated at:
# app/build/outputs/apk/debug/app-debug.apk
```

#### Step 3: Install to Device

```bash
# Install Debug version to connected device
./gradlew installDebug

# Or install the built APK directly using adb
adb install app/build/outputs/apk/debug/app-debug.apk
```

#### Step 4: Launch the App

```bash
# Method 1: Launch using adb
adb shell am start -n com.finclip.chatkit.examples/.MainActivity

# Method 2: Manually tap the app icon on device
# App name: ChatKit Examples
```

#### One-Command Build, Install, and Launch

```bash
# Build, install, and launch in one command
./gradlew installDebug && adb shell am start -n com.finclip.chatkit.examples/.MainActivity
```

### Method 3: Using Android Studio

#### Step 1: Open Project

1. Launch Android Studio
2. Select **File → Open**
3. Select the `demo-apps/Android` directory
4. Wait for Gradle sync to complete

#### Step 2: Configure Run Device

1. Select run configuration from top toolbar
2. Choose connected device or emulator
3. If no device available, click **Device Manager** to create an emulator

#### Step 3: Run the App

1. Click the **Run** button (green triangle) in toolbar or press `Shift + F10`
2. Android Studio will automatically:
   - Build the project
   - Install APK to device
   - Launch the app

#### Step 4: View Logs

- Check app logs in bottom **Logcat** window
- Filter by tag: `ChatKit` or `ExamplesApplication`

### Method 3: Direct APK Installation

If you already have a built APK file:

```bash
# Install using adb
adb install app/build/outputs/apk/debug/app-debug.apk

# Or transfer APK to device and install manually
# 1. Copy APK to device
adb push app/build/outputs/apk/debug/app-debug.apk /sdcard/Download/

# 2. Open file manager on device, find APK and install
```

### Verify Installation

After successful installation, verify with:

```bash
# Check if app is installed
adb shell pm list packages | grep chatkit
# Should output: package:com.finclip.chatkit.examples

# View app info
adb shell dumpsys package com.finclip.chatkit.examples | grep versionName
# Should show version: versionName=1.0.0
```

### Configure Server Mode

When you first launch the app, click the **Settings** icon (⚙️) in the top-right corner:

1. **Mock Mode**: Enable to test offline without a real server
2. **Server URL**: Enter your ChatKit backend URL when not in mock mode

### Troubleshooting

#### Issue 1: Device Not Connected

```bash
# Check device connection
adb devices

# If no device, try:
# - Check if USB debugging is enabled
# - Reconnect USB cable
# - Restart adb service
adb kill-server && adb start-server
```

#### Issue 2: GitHub Packages Authentication Failed

**Error**: `401 Unauthorized` or `Could not resolve dependency`

**Solution**:
```bash
# Check environment variables
echo $GITHUB_USERNAME
echo $GITHUB_TOKEN

# Or check Gradle properties
cat ~/.gradle/gradle.properties | grep gpr

# Ensure token has read:packages permission
```

#### Issue 3: Build Failed

```bash
# Clean build cache
./gradlew clean

# Rebuild
./gradlew assembleDebug

# View detailed error
./gradlew assembleDebug --stacktrace
```

#### Issue 4: App Launch Failed

```bash
# View app logs
adb logcat | grep -i chatkit

# View crash logs
adb logcat | grep -i "AndroidRuntime"

# Clear app data and reinstall
adb uninstall com.finclip.chatkit.examples
./gradlew installDebug
```

---

## 📱 Example List

| # | Example | Description | Key APIs |
|---|---------|-------------|----------|
| 1 | [Simple Chat](#1-simple-chat) | Minimal chat setup | `ChatKit.createCoordinator()`, `ChatFragment` |
| 2 | [Configuration](#2-configuration) | Customize chat UI | `ChatKitConfiguration`, `StatusBannerStyle` |
| 3 | [Conversation Management](#3-conversation-management) | CRUD operations | `ChatKitConversationManager`, `ConversationListFragment` |
| 4 | [Context Providers](#4-context-providers) | Add device/network context | `ConversationContextItem`, `ContextAugmenter` |
| 5 | [Compose Example](#5-compose-example) | Jetpack Compose integration | `ChatKitChatView`, `ConnectionStatusBanner` |
| 6 | [Full Feature](#6-full-feature) | All features combined | Complete SDK integration |
| 7 | [Advanced APIs](#7-advanced-apis) | Low-level APIs & customization | `NeuronRuntime`, custom providers |

---

## 📦 Dependencies

This demo app uses the following SDKs from GitHub Packages:

| Package | Version | Description |
|---------|---------|-------------|
| `com.finclip:chatkit` | 1.0.1 | ChatKit Android SDK |
| `com.finclip:convoui` | 1.0.0 | UI Components (transitive) |
| `com.finclip:neuronkit` | 1.0.1 | Core Runtime (transitive) |
| `com.finclip:sandbox` | 1.0.0 | Policy Engine (transitive) |
| `com.finclip:convstore` | 1.0.0 | Message Storage (transitive) |

> Note: Only `chatkit` is declared as a direct dependency. Other SDKs are transitive dependencies.

---

## 1. Simple Chat

**File**: `app/src/main/java/com/finclip/chatkit/examples/simple/SimpleChatActivity.kt`

The simplest way to integrate ChatKit - just a few lines of code to get a working chat interface.

### Features
- Basic chat functionality
- Minimal setup required
- Uses default configuration

### SDK APIs Used

```kotlin
// Create coordinator
val coordinator = ChatKit.createCoordinator(
    context = this,
    serverURL = "wss://your-server.com",
    userId = "user-123"
)

// Start a conversation
val (record, conversation) = coordinator.startConversation(
    agentId = agentId,
    title = "Simple Chat"
)

// Display chat UI
val fragment = ChatFragment.newInstance(record.id)
supportFragmentManager.beginTransaction()
    .replace(R.id.fragmentContainer, fragment)
    .commit()
```

### Test Steps

1. Launch app → Select "1. Simple Chat"
2. Wait for chat interface to load
3. Type a message and send
4. Verify message appears in chat
5. Verify AI response is received (Mock mode: immediate; Server mode: may take a few seconds)

---

## 2. Configuration

**File**: `app/src/main/java/com/finclip/chatkit/examples/config/ConfigurationActivity.kt`

Demonstrates how to customize the chat experience with various configuration options.

### Features
- Custom welcome message
- Prompt starters with callbacks
- Custom status banner styling
- Input field customization
- Pagination settings

### SDK APIs Used

```kotlin
val config = ChatKitConfiguration(
    // Welcome message
    showWelcomeMessage = true,
    welcomeMessageProvider = { record -> "Welcome to ${record.title}!" },
    
    // Prompt starters
    promptStartersEnabled = true,
    promptStartersProvider = {
        listOf(
            FinConvoPromptStarter("id1", "What can you do?", "Learn about capabilities", null, null),
            FinConvoPromptStarter("id2", "Tell me a joke", "Have some fun", null, null)
        )
    },
    promptStarterBehaviorMode = PromptStarterBehaviorMode.AUTO_HIDE,
    onPromptStarterSelected = { starter ->
        Toast.makeText(this, "Selected: ${starter.title}", Toast.LENGTH_SHORT).show()
        false // Return false to continue default behavior
    },
    
    // Status banner
    showStatusBanner = true,
    statusBannerStyle = StatusBannerStyle(
        height = 36,
        fontSize = 14f,
        connectedColor = Color.parseColor("#2E7D32"),
        disconnectedColor = Color.parseColor("#C62828")
    ),
    statusBannerAutoHide = true,
    statusBannerAutoHideDelay = 3000L,
    
    // Input settings
    inputPlaceholder = "Type your message...",
    inputMaxLength = 2000,
    inputAllowsMultiline = true,
    
    // Pagination
    paginationEnabled = true,
    paginationPageSize = 50
)
```

### Test Steps

1. Launch app → Select "2. Configuration"
2. **Welcome Message**: Verify custom welcome appears
3. **Prompt Starters**: Tap a starter, verify Toast shows
4. **Status Banner**: Check connection status displays
5. **Input**: Try multiline input, verify placeholder text

---

## 3. Conversation Management

**File**: `app/src/main/java/com/finclip/chatkit/examples/conversation/ConversationManagementActivity.kt`

Complete demonstration of conversation lifecycle management.

### Features
- Create new conversations
- List all conversations
- Search conversations
- Delete conversations (swipe or batch)
- Pin/unpin conversations
- View historical messages

---

## 4. Context Providers

**File**: `app/src/main/java/com/finclip/chatkit/examples/context/ContextProviderActivity.kt`

Shows how to enrich messages with device and network context information.

### Features
- Device state context (battery, OS version, model)
- Network status context (WiFi/Cellular)
- Context augmentation to messages
- Custom prompt starters for context queries

---

## 5. Compose Example

**File**: `app/src/main/java/com/finclip/chatkit/examples/compose/ComposeExampleActivity.kt`

Demonstrates Jetpack Compose integration with ChatKit.

### Features
- Pure Compose UI
- Compose-based chat view
- Connection status banner (Compose)
- Error handling in Compose
- Loading states

---

## 6. Full Feature

**File**: `app/src/main/java/com/finclip/chatkit/examples/full/FullFeatureActivity.kt`

A comprehensive example combining all SDK features.

### Features
- All configuration options
- Logging with file handler
- Conversation list with full config
- Error handling demonstration
- Connection status monitoring

---

## 7. Advanced APIs

**File**: `app/src/main/java/com/finclip/chatkit/examples/advanced/AdvancedApiActivity.kt`

Demonstrates low-level APIs and advanced customization.

### Features
- Framework info display
- Custom title provider
- Custom connection status provider
- Connection mode switching
- Prompt starter factory
- Minimal/Compact configurations
- Custom error handler
- Low-level runtime API

---

## 🔧 Mock Mode

The examples include a complete Mock implementation for offline development:

### MockRuntime

**File**: `app/src/main/java/com/finclip/chatkit/examples/mock/MockRuntime.kt`

- Simulates AI responses without a server
- Supports all runtime operations
- Context-aware responses (recognizes "hello", "code", "help", etc.)
- Includes mock ConversationRepository

### Switching Modes

```kotlin
// In AppSettings
AppSettings.useMock = true  // Enable mock mode
AppSettings.useMock = false // Use real server

// ChatKitHelper automatically selects the correct implementation
val coordinator = ChatKitHelper.createCoordinator(context)
```

---

## 📁 Project Structure

```
Android/
├── app/
│   └── src/main/java/com/finclip/chatkit/examples/
│       ├── MainActivity.kt              # Example list launcher
│       ├── ExamplesApplication.kt       # Application class
│       │
│       ├── simple/
│       │   └── SimpleChatActivity.kt    # Basic chat example
│       │
│       ├── config/
│       │   └── ConfigurationActivity.kt # Configuration example
│       │
│       ├── conversation/
│       │   └── ConversationManagementActivity.kt  # CRUD example
│       │
│       ├── context/
│       │   └── ContextProviderActivity.kt  # Context providers example
│       │
│       ├── compose/
│       │   └── ComposeExampleActivity.kt   # Jetpack Compose example
│       │
│       ├── full/
│       │   └── FullFeatureActivity.kt   # Complete feature example
│       │
│       ├── advanced/
│       │   └── AdvancedApiActivity.kt   # Advanced APIs example
│       │
│       ├── mock/
│       │   └── MockRuntime.kt           # Offline mock implementation
│       │
│       ├── settings/
│       │   ├── AppSettings.kt           # App configuration
│       │   └── ChatKitHelper.kt         # Helper for coordinator creation
│       │
│       └── ui/theme/
│           └── Theme.kt                 # Compose theme
│
├── build.gradle.kts                     # Root build config
├── settings.gradle.kts                  # Settings with GitHub Packages repos
├── gradle.properties                    # Gradle properties
└── gradle/wrapper/                      # Gradle wrapper
```

---

## 🔗 Related Resources

- [finclip-chatkit Documentation](../../docs/)
- [ChatKit Android SDK](https://github.com/Geeksfino/chatkit-android)
- [NeuronKit Android SDK](https://github.com/Geeksfino/neuronkit-android)
- [ConvoUI Android SDK](https://github.com/Geeksfino/ConvoUI-Android)
