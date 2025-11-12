# ChatKit Integration Guide

This guide covers specific integration scenarios and deployment options for ChatKit.

> 📚 **For learning to build with ChatKit**, see the [Developer Guide](./developer-guide.md) instead.

---

## Table of Contents

1. [Package Manager Setup](#package-manager-setup)
2. [CocoaPods Integration](#cocoapods-integration)
3. [Manual XCFramework Integration](#manual-xcframework)
4. [Build Settings and Configuration](#build-settings)
5. [Deployment and Distribution](#deployment)

---

## Package Manager Setup

### Swift Package Manager (Recommended)

#### Method 1: Package.swift

For Swift Package projects:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)
```

#### Method 2: Xcode UI

For Xcode projects:

1. **File → Add Package Dependencies...**
2. Enter repository URL: `https://github.com/Geeksfino/finclip-chatkit.git`
3. Choose version: `0.3.1` or later
4. Select `ChatKit` product
5. Add to your target

#### Method 3: XcodeGen (project.yml)

For projects using XcodeGen:

```yaml
name: YourApp
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    iOS: "16.0"

packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.3.1

targets:
  YourApp:
    type: application
    platform: iOS
    sources:
      - path: App
    dependencies:
      - package: ChatKit
```

---

## CocoaPods Integration

### Basic Podfile

```ruby
platform :ios, '16.0'
use_frameworks!

target 'YourApp' do
  pod 'ChatKit', '~> 0.3.1'
end
```

### Install and Build

```bash
# Install dependencies
pod install

# Open workspace (not .xcodeproj!)
open YourApp.xcworkspace
```

### Update ChatKit

```bash
# Update to latest version
pod update ChatKit

# Or update all pods
pod update
```

---

## Manual XCFramework

For projects that can't use package managers:

### Step 1: Download

Download `ChatKit.xcframework.zip` from [GitHub Releases](https://github.com/Geeksfino/finclip-chatkit/releases):

```bash
curl -LO https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.3.1/ChatKit.xcframework.zip
unzip ChatKit.xcframework.zip
```

### Step 2: Add to Xcode

1. Drag `ChatKit.xcframework` into your Xcode project
2. Select **Copy items if needed**
3. Add to your app target

### Step 3: Embed Framework

In **General → Frameworks, Libraries, and Embedded Content**:
- Select `ChatKit.xcframework`
- Set to **Embed & Sign**

### Step 4: Import

```swift
import FinClipChatKit
```

---

## Build Settings

### Required Settings

ChatKit requires specific build settings for proper framework resolution.

#### Framework Search Paths

Add these to your target's **Build Settings**:

```
FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*] = $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*] = $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

#### Runpath Search Paths

```
LD_RUNPATH_SEARCH_PATHS = $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
```

#### Swift Include Paths

```
SWIFT_INCLUDE_PATHS[sdk=iphoneos*] = $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*] = $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

### XcodeGen Configuration

If using XcodeGen, add to your `project.yml`:

```yaml
targets:
  YourApp:
    settings:
      ENABLE_BITCODE: NO
      FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

### Code Signing Nested Frameworks

Add a post-build script to sign nested frameworks:

```yaml
postbuildScripts:
  - name: Sign Nested Frameworks
    shell: /bin/sh
    script: |
      FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FinClipChatKit.framework/Frameworks"
      if [ -d "${FRAMEWORK_DIR}" ]; then
        find "${FRAMEWORK_DIR}" -type d -name "*.framework" -print0 | while IFS= read -r -d '' FRAME; do
          /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAME}" || exit 1
        done
      fi
```

---

## Deployment

### App Store Submission

ChatKit is App Store ready. No special steps needed.

**Important**: Ensure you're using **v0.3.1 or later** which includes proper code signing for all nested frameworks.

### TestFlight Beta

Works out of the box. Upload your IPA as normal:

```bash
xcodebuild archive -scheme YourApp -archivePath build/YourApp.xcarchive
xcodebuild -exportArchive -archivePath build/YourApp.xcarchive -exportPath build/YourApp.ipa -exportOptionsPlist ExportOptions.plist
```

### Ad-Hoc Distribution

Same as App Store builds. Ensure proper provisioning profiles.

### Enterprise Distribution

Fully supported. Use your enterprise certificate for code signing.

---

## Platform Support

| Platform | Supported | Minimum Version |
|----------|-----------|----------------|
| iOS | ✅ | 16.0+ |
| iPadOS | ✅ | 16.0+ |
| macOS | ❌ | N/A |
| tvOS | ❌ | N/A |
| watchOS | ❌ | N/A |

---

## Version Requirements

| Tool | Minimum Version |
|------|----------------|
| Xcode | 15.0 |
| Swift | 5.9 |
| iOS | 16.0 |

---

## Dependency Tree

ChatKit bundles these frameworks:

```
ChatKit.xcframework
├── FinClipChatKit.framework (main)
│   ├── NeuronKit.framework
│   ├── ConvoUI.framework
│   ├── SandboxSDK.framework
│   └── convstore.framework (convstorelib)
```

All frameworks are embedded and signed. No additional setup needed.

---

## Troubleshooting Integration

### "Framework not found: FinClipChatKit"

**Solution**: Check framework search paths (see [Build Settings](#build-settings))

### "Library not loaded: @rpath/NeuronKit.framework"

**Solution**: 
1. Check runpath search paths include `@loader_path/Frameworks/FinClipChatKit.framework/Frameworks`
2. Ensure nested frameworks are signed (see post-build script above)

### "Module 'ChatKit' not found"

**Solution**: 
1. Ensure you're importing `FinClipChatKit`, not `ChatKit`
   ```swift
   import FinClipChatKit  // ✅ Correct
   import ChatKit         // ❌ Wrong
   ```
2. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)

### SPM Cache Issues

**Solution**: Reset package caches
```bash
# Clear SPM cache
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# Resolve packages again
swift package resolve
```

### CocoaPods Issues

**Solution**: Update CocoaPods and clear cache
```bash
# Update CocoaPods
sudo gem install cocoapods

# Clear cache
pod cache clean --all
pod deintegrate
pod install
```

---

## Migration Guide

### From v0.2.x to v0.3.x

**Breaking Changes:**
- `ChatKitCoordinator` is now the recommended entry point
- Direct `NeuronRuntime` creation is discouraged

**Migration Steps:**

1. Update dependency version:
   ```swift
   .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
   ```

2. Replace direct runtime creation:
   ```swift
   // ❌ Old way (v0.2.x)
   let runtime = NeuronRuntime(config: config)
   
   // ✅ New way (v0.3.x)
   let coordinator = ChatKitCoordinator(config: config)
   let runtime = coordinator.runtime
   ```

3. Keep coordinator alive:
   ```swift
   class MyViewController: UIViewController {
       private var coordinator: ChatKitCoordinator?  // Store it!
       
       func setup() {
           coordinator = ChatKitCoordinator(config: config)
           // Now use coordinator.runtime
       }
   }
   ```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.0.app
    
    - name: Resolve SPM Dependencies
      run: swift package resolve
    
    - name: Build
      run: swift build
    
    - name: Test
      run: swift test
```

### Fastlane

```ruby
lane :build do
  cocoapods
  
  gym(
    scheme: "YourApp",
    clean: true,
    output_directory: "./build"
  )
end
```

---

## Advanced Topics

### Local Development with Custom ChatKit Build

For developing with a local ChatKit build:

```swift
// In Package.swift
.package(path: "../chatkit/.dist")
```

See [AI-Bank example](../demo-apps/iOS/AI-Bank) for reference.

### Multiple ChatKit Versions

Not recommended. If absolutely needed:
1. Use different product names
2. Namespace your imports
3. Ensure no symbol conflicts

### Custom Framework Bundling

If bundling ChatKit into your own framework:
1. Re-export public symbols
2. Maintain search paths
3. Sign all nested frameworks

---

## Reference Examples

### Minimal SPM Setup

See: `demo-apps/iOS/AI-Bank/Package.swift`

### Full XcodeGen Setup

See: `demo-apps/iOS/Smart-Gov/project.yml` (before simplification)

### CocoaPods Setup

See: `demo-apps/iOS/Smart-Gov/Podfile`

---

## Support

For integration issues:
1. Check [Troubleshooting Guide](./troubleshooting.md)
2. Review [Example Apps](../demo-apps/iOS/)
3. Open [GitHub Issue](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**Next**: [Developer Guide](./developer-guide.md) - Learn to build with ChatKit
