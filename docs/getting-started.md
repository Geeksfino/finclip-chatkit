# Getting Started with ChatKit

Welcome to ChatKit! This guide will help you integrate our conversational AI SDK into your iOS application.

## Quick Start for External Developers

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0+ deployment target
- XcodeGen (`brew install xcodegen`)
- CocoaPods (`sudo gem install cocoapods`) - optional but recommended

### Step 1: Create Your Project

Use our Smart-Gov example as a template. This example demonstrates remote dependency usage without requiring local ChatKit builds.

### Step 2: Configure Your Project

Create a `project.yml` file in your project root:

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
      # Critical: Framework search paths for nested frameworks
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

### Step 3: Build and Run

**Option A: Using CocoaPods (Recommended)**
```bash
# Install prerequisites
brew install xcodegen
sudo gem install cocoapods

# Build and run
cd your-project
make run-cocoapods
```

**Option B: Using SPM**
```bash
# Install prerequisites
brew install xcodegen

# Build and run
cd your-project
make run
```

## Understanding the Framework Structure

ChatKit is a composite XCFramework that bundles:
- **FinClipChatKit.framework** - Main framework
- **NeuronKit.framework** - AI orchestration layer
- **ConvoUI.framework** - UI components
- **SandboxSDK.framework** - Security layer
- **convstore.framework** - Conversation storage

## Integration Examples

### Basic Chat Integration
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

### Custom Configuration
```swift
let config = FinConvoChatConfig(
    apiKey: "your-api-key",
    baseURL: "https://your-api-endpoint.com",
    theme: .light
)
let chatView = FinConvoChatView(config: config)
```

## Troubleshooting

### Common Issues and Solutions

1. **"Framework not found" errors**
   - Ensure `FinClipChatKit.framework` is used in all search paths
   - Check that package name is `ChatKit` in project.yml

2. **Build failures**
   - Verify XcodeGen is installed: `brew install xcodegen`
   - Check that all framework search paths are correctly set

3. **Runtime crashes**
   - Ensure nested frameworks are properly signed
   - Verify deployment target is iOS 16.0+

## Next Steps

1. **Explore the Smart-Gov example** - Complete working example with remote dependencies
2. **Check the architecture guide** - Understand the framework structure
3. **Review customization options** - See how to customize the UI
4. **Read the reference documentation** - Full API documentation

## Support

For issues or questions:
- Check the troubleshooting guide above
- Review the Smart-Gov example for reference
- File issues on the GitHub repository

## Quick Commands

```bash
# Generate Xcode project
make generate

# Build and run with CocoaPods
make run-cocoapods

# Build and run with SPM
make run

# Clean build artifacts
make clean

# Test dependencies
make validate-deps
```
