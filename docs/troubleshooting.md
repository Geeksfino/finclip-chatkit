# Troubleshooting Guide

Common issues and solutions when working with ChatKit, based on real debugging experiences.

---

## Quick Fixes

| Problem | Solution |
|---------|----------|
| `ChatKitCoordinator` not found | Update to v0.3.1+ |
| Framework not found | Check build settings (see below) |
| Conversations lost on agent switch | Use connection mode check |
| Module not found | Import `FinClipChatKit`, not `ChatKit` |
| SPM cache issues | Clear DerivedData |

---

## Build Issues

### ChatKitCoordinator Not Found

**Symptoms:**
```
error: cannot find type 'ChatKitCoordinator' in scope
```

**Root Cause:**
You're using an older version of ChatKit (v0.2.x or earlier) that doesn't include `ChatKitCoordinator`.

**Solution:**
Update to v0.3.1 or later:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
]
```

Then clean and rebuild:
```bash
rm -rf .build ~/Library/Developer/Xcode/DerivedData
swift package resolve
swift build
```

---

### Module 'ChatKit' Not Found

**Symptoms:**
```
error: no such module 'ChatKit'
```

**Root Cause:**
Wrong import statement. The module name is `FinClipChatKit`.

**Solution:**
Use the correct import:

```swift
import FinClipChatKit  // ✅ Correct
import ChatKit         // ❌ Wrong
```

---

### Framework Not Found

**Symptoms:**
- Build fails with "Framework not found: FinClipChatKit"
- Linker errors about missing frameworks
- "No such module 'ConvoUI'" or "No such module 'NeuronKit'"

**Root Cause:**
Missing or incorrect framework search paths.

**Solution:**
Add these build settings to your target:

**For Xcode projects:**
1. Select your target → Build Settings
2. Add to **Framework Search Paths**:
   ```
   $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
   ```

**For XcodeGen (project.yml):**
```yaml
targets:
  YourApp:
    settings:
      FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
      SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

> **Note:** The framework name is `FinClipChatKit.framework`, NOT `ChatKit.framework`.

---

### Library Not Loaded at Runtime

**Symptoms:**
```
dyld: Library not loaded: @rpath/NeuronKit.framework/NeuronKit
```

**Root Cause:**
Nested frameworks aren't signed or runpath is incorrect.

**Solution 1: Check Runpath**
Ensure `LD_RUNPATH_SEARCH_PATHS` includes:
```
@loader_path/Frameworks/FinClipChatKit.framework/Frameworks
```

**Solution 2: Sign Nested Frameworks**
Add a post-build script:

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

### SPM Cache Issues

**Symptoms:**
- Package resolution fails
- Stale dependency versions
- Cached build artifacts causing issues

**Solution:**
Clear all caches:

```bash
# Clear SPM cache
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData

# Resolve again
swift package resolve
swift package update
```

**For Xcode:**
1. **Product → Clean Build Folder** (⇧⌘K)
2. **File → Packages → Reset Package Caches**
3. Rebuild

---

### CocoaPods Issues

**Symptoms:**
- `pod install` fails
- Version conflicts
- Framework not found after pod install

**Solution:**

```bash
# Clear CocoaPods cache
pod cache clean --all

# Remove old installation
pod deintegrate
rm -rf Pods
rm Podfile.lock

# Reinstall
pod install

# Always open .xcworkspace, not .xcodeproj!
open YourApp.xcworkspace
```

---

## Runtime Issues

### Conversations Lost on Agent Switch

**Symptoms:**
- Switching to a new agent loses all conversations
- Previous messages disappear
- Session state is reset

**Root Cause:**
Recreating `NeuronRuntime` unnecessarily, which destroys the previous runtime and all its state.

**Solution:**
Check if reconnection is truly needed:

```swift
private func startConversationWithAgent(_ agent: AgentProfile) {
    // ✅ Only reconnect if necessary
    let needsReconnect = coordinator.neuronRuntime == nil ||
                         !coordinator.isSameConnectionMode(agent.connectionMode)
    
    if needsReconnect {
        coordinator.reconnect(mode: agent.connectionMode)
    }
    
    // Continue with conversation setup...
}
```

**Best Practice:**
Always use `ChatKitCoordinator` instead of creating `NeuronRuntime` directly:

```swift
// ❌ DON'T: Direct creation destroys previous runtime
let runtime = NeuronRuntime(config: config)

// ✅ DO: Use coordinator for safe lifecycle
let coordinator = ChatKitCoordinator(config: config)
let runtime = coordinator.runtime
```

---

### Conversations Not Persisting

**Symptoms:**
- Conversations disappear after app restart
- History is empty
- Sessions aren't saved

**Root Cause:**
Not using `conversationRepository` to persist conversations.

**Solution:**
Always persist conversations to convstore:

```swift
func createConversation(agent: AgentProfile) {
    guard let runtime = coordinator?.runtime else { return }
    
    let sessionId = UUID()
    let conversation = runtime.openConversation(
        sessionId: sessionId,
        agentId: agent.id
    )
    
    // ✅ Persist to convstore
    Task {
        guard let repo = runtime.conversationRepository else { return }
        do {
            try await repo.ensureAgent(id: agent.id, name: agent.name)
            try await repo.ensureConversation(
                sessionId: sessionId,
                agentId: agent.id,
                deviceId: deviceId
            )
        } catch {
            print("Failed to persist: \(error)")
        }
    }
}
```

---

### Messages Not Updating in UI

**Symptoms:**
- UI doesn't update when new messages arrive
- Message list is stale
- No real-time updates

**Root Cause:**
Not observing the conversation's message publisher.

**Solution:**
Subscribe to message updates:

```swift
import Combine

var cancellables = Set<AnyCancellable>()

func observeMessages(conversation: Conversation) {
    conversation.messagesPublisher
        .receive(on: DispatchQueue.main)
        .sink { [weak self] messages in
            self?.updateUI(with: messages)
        }
        .store(in: &cancellables)
}
```

**Don't forget to:**
1. Store the `AnyCancellable` (don't let it be deallocated)
2. Cancel subscriptions when done: `cancellables.forEach { $0.cancel() }`

---

### Memory Leaks

**Symptoms:**
- App memory grows over time
- Conversations not released
- Runtime not deallocated

**Root Cause:**
Strong reference cycles or not unbinding UI.

**Solution:**
Always unbind UI when destroying conversations:

```swift
func deleteConversation(sessionId: UUID) {
    if let conversation = conversations[sessionId] {
        // ✅ Unbind UI before removing
        conversation.unbindUI()
    }
    conversations.removeValue(forKey: sessionId)
    
    // Cancel subscriptions
    subscriptions[sessionId]?.cancel()
    subscriptions.removeValue(forKey: sessionId)
}
```

**Use weak references in closures:**
```swift
conversation.messagesPublisher
    .sink { [weak self] messages in  // ✅ weak self
        self?.updateUI(with: messages)
    }
    .store(in: &cancellables)
```

---

## Configuration Issues

### Invalid Package Name

**Symptoms:**
- XcodeGen fails with package resolution errors
- "Unknown package" errors

**Root Cause:**
Wrong package name in `project.yml` or `Package.swift`.

**Solution:**
Use `ChatKit` as the package name (not `finclip-chatkit`):

**XcodeGen (project.yml):**
```yaml
packages:
  ChatKit:  # ✅ Correct
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.3.1
```

**Package.swift:**
```swift
.product(name: "ChatKit", package: "finclip-chatkit")  // ✅ Correct
```

---

### Version Mismatch

**Symptoms:**
- Features not available
- API changes cause compile errors
- Missing symbols

**Solution:**
Ensure you're using v0.3.1 or later:

**Package.swift:**
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
```

**Podfile:**
```ruby
pod 'ChatKit', :podspec => 'https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/ChatKit.podspec'
```

Then update:
```bash
# SPM
swift package update

# CocoaPods
pod update ChatKit
```

---

### Missing Resources

**Symptoms:**
- Assets not found
- Images missing
- Crashes when accessing resources

**Solution:**
SPM auto-discovers resources by default. If needed, explicitly add:

```swift
.target(
    name: "YourApp",
    dependencies: [...],
    resources: [.process("Resources")]  // If needed
)
```

---

## Platform Issues

### "Unsupported platform" Errors

**Symptoms:**
```
error: platform 'macOS' is not supported
```

**Root Cause:**
ChatKit only supports iOS 16.0+.

**Solution:**
Ensure correct platform specification:

```swift
platforms: [
    .iOS(.v16)  // ✅ iOS platform requirement
]
```

---

### Deployment Target Too Low

**Symptoms:**
- Compile errors about unavailable APIs
- "Minimum deployment target is iOS 16.0"

**Solution:**
Set deployment target to iOS 16.0 or higher:

```yaml
deploymentTarget:
  iOS: "16.0"
```

---

## Debugging Tools

### Verify Framework Bundle

Check what's inside the framework:

```bash
# List frameworks
ls -la ChatKit.xcframework/ios-arm64/FinClipChatKit.framework/Frameworks/

# Check symbols
nm ChatKit.xcframework/ios-arm64/FinClipChatKit.framework/FinClipChatKit | grep ChatKitCoordinator
```

### Enable Verbose Logging

```swift
// Add to AppDelegate or main
print("Runtime: \(coordinator.runtime)")
print("Conversations: \(conversationManager.recordsSnapshot())")
```

### Check Package Resolution

```bash
# Show resolved dependencies
swift package show-dependencies

# Describe package
swift package describe
```

---

## Real-World Examples

### Case Study 1: ChatKitCoordinator Not Found

**Problem:**
AI-Bank demo failed to build with "cannot find type 'ChatKitCoordinator'".

**Investigation:**
- Confirmed `ChatKitCoordinator` exists in source
- Checked it's public and in build config
- Found remote binary (v0.3.0) didn't include it

**Solution:**
Released v0.3.1 with rebuilt framework including `ChatKitCoordinator`.

**Lesson:**
Always verify remote binary releases match the source code.

---

### Case Study 2: Conversations Lost

**Problem:**
Smart-Gov lost all conversations when switching agents.

**Investigation:**
- Found runtime was being recreated on every agent switch
- No check for whether reconnection was truly needed

**Solution:**
Added `isSameConnectionMode` check:

```swift
let needsReconnect = coordinator.neuronRuntime == nil ||
                     !coordinator.isSameConnectionMode(agent.connectionMode)
```

**Lesson:**
Only recreate runtime when connection actually changes.

---

## Debugging Checklist

When encountering issues, verify:

### Build Time
- [ ] Using ChatKit v0.3.1 or later
- [ ] Importing `FinClipChatKit`, not `ChatKit`
- [ ] Framework search paths include `FinClipChatKit.framework/Frameworks`
- [ ] Runpath search paths are correct
- [ ] Post-build script signs nested frameworks
- [ ] Deployment target is iOS 16.0+
- [ ] Using correct package name (`ChatKit`)

### Runtime
- [ ] Using `ChatKitCoordinator` (not direct `NeuronRuntime`)
- [ ] Checking connection mode before reconnecting
- [ ] Persisting conversations to convstore
- [ ] Observing message publishers
- [ ] Unbinding UI when destroying conversations
- [ ] Using `weak self` in closures
- [ ] Canceling subscriptions on cleanup

---

## Getting Help

### Self-Service
1. Check this troubleshooting guide
2. Review [Getting Started Guide](./getting-started.md) or [Quick Start Guide](./quick-start.md)
3. Study working examples:
   - See [Running Demos](./running-demos.md) for complete instructions
   - `demo-apps/iOS/Simple/` - Swift example
   - `demo-apps/iOS/SimpleObjC/` - Objective-C example

### Community Support
1. Search [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
2. Check [Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)
3. Open a new issue with:
   - ChatKit version
   - Xcode version
   - Complete error message
   - Minimal reproduction steps

### Reporting Bugs
Include:
```
- ChatKit version: 0.3.1
- Xcode version: 15.0
- iOS deployment target: 16.0
- Package manager: SPM / CocoaPods
- Error message: [paste here]
- Steps to reproduce: [list here]
```

---

## Useful Commands

```bash
# Clean build
rm -rf .build ~/Library/Developer/Xcode/DerivedData
xcodebuild clean -scheme YourApp

# Reset SPM
swift package reset
swift package resolve
swift package update

# Check dependencies
swift package show-dependencies

# Verify framework
unzip -l ChatKit.xcframework.zip | grep ChatKitCoordinator

# Check symbols
nm -gU ChatKit.xcframework/*/FinClipChatKit.framework/FinClipChatKit | grep -i coordinator
```

---

**Next Steps**:
- **[Getting Started Guide](./getting-started.md)** - Learn ChatKit patterns and best practices
- **[Quick Start Guide](./quick-start.md)** - Minimal skeleton code
- **[Swift Developer Guide](./guides/developer-guide.md)** - Comprehensive Swift patterns
- **[Objective-C Developer Guide](./guides/objective-c-guide.md)** - Complete Objective-C guide
