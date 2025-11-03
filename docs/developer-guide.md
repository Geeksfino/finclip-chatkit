# Smart-Gov Example: External Developer Guide

## Overview

This is the **Smart-Gov** demo application - an example iOS app that uses **ChatKit** via remote dependencies (SPM/CocoaPods). 

**Key Point**: This example is designed for **developers who want to use ChatKit SDK to develop their mobile applications with Conversational UI**. It demonstrates how to build an iOS app using ChatKit as a remote binary dependency.

---

## Prerequisites

- **Xcode 16.2+** (or latest compatible version)
- **Swift 6.0+**
- **iOS 16.0+** deployment target
- **XcodeGen** (for project generation)
- **CocoaPods** (optional, for testing CocoaPods integration)

### Install XcodeGen

```bash
brew install xcodegen
```

### (Optional) Install CocoaPods

```bash
sudo gem install cocoapods
```

---

## Quick Start: Run the App

```bash
cd demo-apps/iOS/Smart-Gov

# ⭐ RECOMMENDED: Using CocoaPods (most reliable)
make run-cocoapods

# OR: Using SPM (may have cache issues in some environments)
make run
```

**That's it!** 

### Using CocoaPods (Recommended)
Xcode will automatically:
1. Create a Podfile with ChatKit dependency
2. Run `pod install` to download the binary
3. Build the xcworkspace
4. Launch on iOS Simulator

### Using SPM (Alternative)
If you prefer SPM:
1. Generate Xcode project (`make generate`)
2. Resolve ChatKit from GitHub
3. Download the binary XCFramework
4. Build and link your app

**Note**: SPM may have cache permission issues in sandboxed development environments. If `make run` fails, use `make run-cocoapods` instead.

---

## Architecture: Remote Dependencies

### How It Works

```
Your iOS App
    ↓
Package.swift (defines remote dependency)
    ↓
GitHub: https://github.com/Geeksfino/finclip-chatkit
    ↓
ChatKit v0.1.0 Release
    ↓
ChatKit.xcframework.zip (prebuilt binary)
    ↓
Xcode downloads & embeds in your app
```

### Option 1: Swift Package Manager (SPM) - Recommended

**File**: `Package.swift`

```swift
dependencies: [
    .package(
        url: "https://github.com/Geeksfino/finclip-chatkit.git",
        from: "0.1.0"
    )
],
targets: [
    .target(
        name: "iLoveHK-App",
        dependencies: [
            .product(name: "ChatKit", package: "finclip-chatkit")
        ]
    )
]
```

**In Xcode**:
```yaml
# project.yml
packages:
  finclip-chatkit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.1.0

targets:
  iLoveHK:
    dependencies:
      - package: finclip-chatkit
        product: ChatKit
```

### Option 2: CocoaPods

**File**: `Podfile` (auto-generated)

```ruby
platform :ios, '16.0'

target 'iLoveHK' do
  # Uses direct binary podspec reference from GitHub
  # This works without ChatKit being published to CocoaPods registry
  pod "ChatKit", :podspec => "https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/v0.2.1/ChatKit.podspec"
end
```

**How It Works:**
- CocoaPods fetches the podspec directly from GitHub
- Downloads the prebuilt XCFramework binary from the release
- Creates Pods/ directory and xcworkspace
- No dependencies - ChatKit bundles everything (NeuronKit, ConvoUI, etc.)

**Advantages:**
- ✅ Works without CocoaPods registry publication
- ✅ Reliable binary downloading
- ✅ Standard iOS development workflow
- ✅ Creates xcworkspace for managing dependencies

---

## Available Commands

### Build & Run

| Command | Purpose |
|---------|---------|
| `make generate` | Generate Xcode project from `project.yml` |
| `make open` | Open Xcode project in IDE |
| `make run` | **Build & run on iOS Simulator** (recommended) |
| `make clean` | Clean all build artifacts |
| `make uninstall` | Remove app from simulator |

### Testing Dependencies

| Command | Purpose |
|---------|---------|
| `make validate-deps` | Validate both SPM and CocoaPods can resolve ChatKit |
| `make test-spm` | Validate SPM Package.swift configuration |
| `make test-cocoapods` | Validate CocoaPods Podfile configuration |

### Information

| Command | Purpose |
|---------|---------|
| `make help` | Display all available commands |

---

## Detailed Usage

### 1. Generate Project

```bash
make generate
```

This uses `xcodegen` to generate `iLoveHK.xcodeproj` from `project.yml`. The project includes:
- SPM package reference to remote ChatKit
- iOS app target with proper settings
- Pre/post-build scripts for icons and framework signing

### 2. Build & Run

```bash
make run
```

This will:
1. ✅ Generate project (if not already done)
2. ✅ Xcode reads `project.yml` with SPM dependency
3. ✅ SPM resolves `finclip-chatkit` package from GitHub
4. ✅ Downloads `ChatKit.xcframework` binary from release
5. ✅ Xcode builds the app
6. ✅ Launches on iOS Simulator

### 3. Validate Dependencies

```bash
make validate-deps
```

Tests that:
- ✅ Package.swift syntax is valid
- ✅ Remote ChatKit repository is accessible
- ✅ GitHub release v0.1.0 exists
- ✅ Binary XCFramework is downloadable

---

## Project Structure

```
demo-apps/iOS/Smart-Gov/
├── App/                          # Application source code
│   ├── App/                      # App delegate, scene delegate
│   ├── Coordinators/             # Runtime & conversation management
│   ├── Models/                   # Data models (agents, conversations)
│   ├── Network/                  # Network adapters & mocks
│   ├── ViewControllers/          # UI screens
│   └── Resources/                # Assets, videos, fixtures
│
├── Package.swift                 # ← SPM manifest (remote ChatKit dependency)
├── project.yml                   # ← XcodeGen config (generates Xcode project)
├── Makefile                      # ← Build commands
├── Podfile                       # ← CocoaPods manifest (auto-generated)
│
├── iLoveHK.xcodeproj/           # Generated Xcode project
├── build/                        # Build artifacts (generated)
└── README files                  # Documentation
```

---

## Troubleshooting

### Issue: "Cannot find ChatKit in scope"

**Cause**: Package.swift not found or SPM not resolving dependency.

**Solution**:
```bash
swift package reset --package-path .
make generate
make run
```

### Issue: "XcodeGen not installed"

**Solution**:
```bash
brew install xcodegen
```

### Issue: "ChatKit XCFramework not found"

**Cause**: GitHub release v0.1.0 not published or network issue.

**Solution**:
```bash
# Verify GitHub release is accessible
curl -I https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip
```

### Issue: Build fails with "Missing dependencies"

**Cause**: Nested frameworks not properly embedded.

**Solution**:
- Ensure `project.yml` has `embed: true` for ChatKit package dependency
- Check that code signing script runs in post-build phase
- Clean and rebuild: `make clean && make run`

### Issue: "Cannot find pod ChatKit"

**Cause**: ChatKit not yet published to CocoaPods registry.

**Solution**:
- Use SPM (recommended) instead: `make run`
- Or wait for CocoaPods publication

---

## Integration into Your Own App

### Step 1: Create Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "MyApp", targets: ["MyApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "MyApp",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ],
            path: "Sources"
        )
    ]
)
```

### Step 2: Create project.yml

```yaml
name: MyApp
options:
  bundleIdPrefix: com.yourcompany

packages:
  finclip-chatkit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.1.0

targets:
  MyApp:
    type: application
    platform: iOS
    deploymentTarget: "16.0"
    sources:
      - path: Sources
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.myapp
    dependencies:
      - package: finclip-chatkit
        product: ChatKit
```

### Step 3: Generate & Build

```bash
xcodegen generate
xcodebuild -project MyApp.xcodeproj -scheme MyApp -destination "platform=iOS Simulator,name=iPhone 16"
```

---

## Import ChatKit in Your App

```swift
import ChatKit

// Use ChatKit components
let chatView = FinConvoChatView()
let adapter = ChatKitAdapter(chatView: chatView)
```

See `App/ViewControllers/MainChatViewController.swift` for full integration example.

---

## Validation Results

✅ **SPM Validation**
- ✅ Package.swift syntax valid
- ✅ Remote dependency URL correct
- ✅ Version constraint proper (from: "0.1.0")
- ✅ ChatKit product declared
- ✅ GitHub release v0.1.0 available (HTTP 200)
- ✅ Binary artifact downloadable

✅ **Xcode Project Generation**
- ✅ XcodeGen generates valid project
- ✅ SPM package references correct
- ✅ Build settings configured
- ✅ Framework embedding enabled

---

## Key Differences from Local Development

| Aspect | Local Development | External Developer |
|--------|-------------------|-------------------|
| **ChatKit Source** | Local `../chatkit/` | GitHub remote repository |
| **Build Process** | Build ChatKit XCFramework first | Automatic binary download |
| **Dependencies** | All local (neuronkit, ConvoUI) | All bundled in ChatKit binary |
| **Build Time** | Slow (builds all dependencies) | Fast (downloads prebuilt binary) |
| **Modifications** | Can edit ChatKit source | Must use published releases |
| **Setup** | Complex (requires full repo) | Simple (just clone this folder) |

---

## References

### Files
- **Package.swift** - Swift Package Manager manifest
- **project.yml** - XcodeGen project configuration  
- **Makefile** - Build automation
- **App/** - Application source code

### External Links
- [ChatKit Repository](https://github.com/Geeksfino/finclip-chatkit)
- [ChatKit v0.1.0 Release](https://github.com/Geeksfino/finclip-chatkit/releases/tag/v0.1.0)
- [Swift Package Manager Docs](https://developer.apple.com/documentation/swift_packages)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

---

## Support & Feedback

For issues with:
- **Smart-Gov Example**: Check this guide
- **ChatKit Framework**: See [ChatKit Repository](https://github.com/Geeksfino/finclip-chatkit)
- **SPM Integration**: See [Swift Package Manager Documentation](https://developer.apple.com/documentation/swift_packages)

---

**Last Updated**: November 3, 2025
**Status**: ✅ Production Ready
**Version**: 1.0
