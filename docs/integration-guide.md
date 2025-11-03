# ChatKit Integration Guide

## Overview
This guide provides step-by-step instructions for integrating ChatKit into your iOS application using remote dependencies.

## Quick Start

### 1. Project Setup
Use our Smart-Gov example as a template:

```bash
git clone https://github.com/Geeksfino/finclip-chatkit.git
cd finclip-chatkit/demo-apps/iOS/Smart-Gov
```

### 2. Configuration
Copy the working `project.yml` configuration:

```yaml
name: YourApp
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    iOS: "16.0"

packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.1.0

targets:
  YourApp:
    type: application
    platform: iOS
    sources:
      - path: App
    resources:
      - App/Resources/Assets.xcassets
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.yourapp
      PRODUCT_NAME: YourApp
      INFOPLIST_KEY_CFBundleDisplayName: YourApp
      INFOPLIST_FILE: App/Info.plist
      ENABLE_BITCODE: NO
      FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
    dependencies:
      - package: ChatKit
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

### 3. Build Commands

**Using CocoaPods (Recommended):**
```bash
make run-cocoapods
```

**Using SPM:**
```bash
make run
```

## Key Configuration Points

### Framework Name
The actual framework name is `FinClipChatKit.framework`, not `ChatKit.framework`. This is critical for all search paths.

### Package Name
Use `ChatKit` as the package name in project.yml.

### Version
Use version `0.1.0` consistently.

## Examples

### Basic Integration
```swift
import ChatKit

class ChatViewController: UIViewController {
    private var chatView: FinConvoChatView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chatView = FinConvoChatView()
        chatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chatView)
        
        NSLayoutConstraint.activate([
            chatView.topAnchor.constraint(equalTo: view.topAnchor),
            chatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
```

## Troubleshooting

See `troubleshooting.md` for detailed solutions to common issues.
