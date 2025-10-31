# Getting Started with Finclip ChatKit

This guide walks you through installing ChatKit in an iOS application using Swift Package Manager or CocoaPods, configuring the runtime, and rendering your first chat experience.

## 1. Prerequisites

- Xcode 16.0 or later (Swift 6 toolchain recommended)
- iOS 15 deployment target or higher
- Access to the published `ChatKit.xcframework` release (see the latest GitHub release in this repository)

## 2. Install ChatKit via Swift Package Manager

1. Open your Xcode project.
2. Navigate to **File ▸ Add Package Dependencies…**
3. Enter the repository URL:

   ```text
   https://github.com/Geeksfino/finclip-chatkit.git
   ```

4. Select the latest tagged version (e.g. `v0.1.0`).
5. Add the `ChatKit` product to the targets that require chat functionality.

Your `Package.swift` entry should look like:

```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.1.0")
```

> **Critical:** The `ChatKit` binary bundles several nested frameworks (`FinClipChatKit`, `ConvoUI`, `NeuronKit`, `SandboxSDK`, `convstorelib`). Xcode must be told where to find those nested frameworks when you consume ChatKit via SwiftPM.

### Required Xcode Build Settings

After adding the package, update the target that links ChatKit with the following build configuration changes:

- **Framework Search Paths**
  - `$(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks`
- **Runpath Search Paths**
  - `$(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks`
- **Swift Include Paths**
  - `$(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks`

These settings ensure the Swift compiler and dynamic loader can resolve the nested dependencies that FinClipChatKit re-exports.

Finally, add a post-build script to re-sign the embedded frameworks so Xcode will launch the app in the simulator:

```sh
FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FinClipChatKit.framework/Frameworks"
if [ -d "${FRAMEWORK_DIR}" ]; then
  find "${FRAMEWORK_DIR}" -type d -name "*.framework" -print0 | while IFS= read -r -d '' FRAME; do
    /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAME}" || exit 1
  done
fi
```

For XcodeGen users, the equivalent YAML snippet is:

```yaml
settings:
  FRAMEWORK_SEARCH_PATHS: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
  SWIFT_INCLUDE_PATHS: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
postbuildScripts:
  - name: Sign Nested ChatKit Frameworks
    shell: /bin/sh
    script: |
      FRAMEWORK_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/FinClipChatKit.framework/Frameworks"
      if [ -d "${FRAMEWORK_DIR}" ]; then
        find "${FRAMEWORK_DIR}" -type d -name "*.framework" -print0 | while IFS= read -r -d '' FRAME; do
          /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" --preserve-metadata=identifier,entitlements "${FRAME}" || exit 1
        done
      fi
```

## 3. Install ChatKit via CocoaPods

1. Ensure you have CocoaPods 1.13+ installed.
2. Add ChatKit to your `Podfile`:

   ```ruby
   target 'YourApp' do
     use_frameworks!
     pod 'ChatKit', '~> 0.1.0'
   end
   ```

3. Run `pod install`.
4. Open the generated `.xcworkspace` and build.

## 4. Initialize the SDK

After linking the framework, configure ChatKit at application launch:

```swift
import ChatKit
import NeuronKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let runtime = ChatKitRuntime(configuration: .default)
    ChatKit.shared.start(runtime: runtime)
    return true
  }
}
```

## 5. Render the Conversation UI

```swift
import SwiftUI
import ChatKit

struct ConversationView: View {
  let sessionId: String

  var body: some View {
    ChatKitView(sessionId: sessionId)
      .applyDefaultTheme()
  }
}
```

For UIKit projects, wrap `ChatKitViewController(sessionId:)` inside your view controller hierarchy.

## 6. Configure NeuronKit (Optional)

ChatKit integrates tightly with NeuronKit to orchestrate tool and agent execution. Follow `docs/architecture/neuronkit-integration.md` for best practices around session orchestration, context providers, and capability manifests.

## 7. Next Steps

- Explore the `Examples/` directory for runnable reference projects.
- Review `docs/how-to/customize-ui.md` to theme ChatKit for your brand.
- Read `docs/reference/runtime.md` for full API coverage.
- If you are an AI agent, start with `docs/ai-agents/mission.md` to learn the execution protocol.

Need help? Open an issue or reach out via the Discussions tab.
