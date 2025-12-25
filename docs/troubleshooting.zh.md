# 故障排除指南

在使用 ChatKit 时遇到的常见问题和解决方案，基于实际调试经验。

---

## 快速修复

| 问题 | 解决方案 |
|---------|----------|
| `ChatKitCoordinator` 未找到 | 更新到 v0.3.1+ |
| 框架未找到 | 检查构建设置（见下文）|
| 切换代理时会话丢失 | 使用连接模式检查 |
| 模块未找到 | 导入 `FinClipChatKit`，而不是 `ChatKit` |
| SPM 缓存问题 | 清除 DerivedData |

---

## 构建问题

### ChatKitCoordinator 未找到

**症状：**
```
error: cannot find type 'ChatKitCoordinator' in scope
```

**根本原因：**
您使用的是不包含 `ChatKitCoordinator` 的旧版本 ChatKit（v0.2.x 或更早）。

**解决方案：**
更新到 v0.3.1 或更高版本：

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
]
```

然后清理并重建：
```bash
rm -rf .build ~/Library/Developer/Xcode/DerivedData
swift package resolve
swift build
```

---

### 模块 'ChatKit' 未找到

**症状：**
```
error: no such module 'ChatKit'
```

**根本原因：**
导入语句错误。模块名称是 `FinClipChatKit`。

**解决方案：**
使用正确的导入：

```swift
import FinClipChatKit  // ✅ 正确
import ChatKit         // ❌ 错误
```

---

### 框架未找到

**症状：**
- 构建失败，提示"Framework not found: FinClipChatKit"
- 关于缺少框架的链接器错误
- "No such module 'ConvoUI'" 或 "No such module 'NeuronKit'"

**根本原因：**
缺少或不正确的框架搜索路径。

**解决方案：**
向您的目标添加这些构建设置：

**对于 Xcode 项目：**
1. 选择您的目标 → Build Settings
2. 添加到 **Framework Search Paths**：
   ```
   $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
   ```

**对于 XcodeGen（project.yml）：**
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

> **注意：** 框架名称是 `FinClipChatKit.framework`，不是 `ChatKit.framework`。

---

### 运行时库未加载

**症状：**
```
dyld: Library not loaded: @rpath/NeuronKit.framework/NeuronKit
```

**根本原因：**
嵌套框架未签名或 runpath 不正确。

**解决方案 1：检查 Runpath**
确保 `LD_RUNPATH_SEARCH_PATHS` 包含：
```
@loader_path/Frameworks/FinClipChatKit.framework/Frameworks
```

**解决方案 2：签名嵌套框架**
添加后构建脚本：

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

### SPM 缓存问题

**症状：**
- 包解析失败
- 陈旧的依赖版本
- 缓存的构建产物导致问题

**解决方案：**
清除所有缓存：

```bash
# 清除 SPM 缓存
rm -rf .build
rm -rf ~/Library/Developer/Xcode/DerivedData

# 再次解析
swift package resolve
swift package update
```

**对于 Xcode：**
1. **Product → Clean Build Folder**（⇧⌘K）
2. **File → Packages → Reset Package Caches**
3. 重建

---

### CocoaPods 问题

**症状：**
- `pod install` 失败
- 版本冲突
- pod install 后框架未找到

**解决方案：**

```bash
# 清除 CocoaPods 缓存
pod cache clean --all

# 删除旧安装
pod deintegrate
rm -rf Pods
rm Podfile.lock

# 重新安装
pod install

# 始终打开 .xcworkspace，而不是 .xcodeproj！
open YourApp.xcworkspace
```

---

## 运行时问题

### 切换代理时会话丢失

**症状：**
- 切换到新代理会丢失所有会话
- 之前的消息消失
- 会话状态被重置

**根本原因：**
不必要地重新创建 `NeuronRuntime`，这会销毁先前的运行时及其所有状态。

**解决方案：**
检查是否真的需要重新连接：

```swift
private func startConversationWithAgent(_ agent: AgentProfile) {
    // ✅ 仅在必要时重新连接
    let needsReconnect = coordinator.neuronRuntime == nil ||
                         !coordinator.isSameConnectionMode(agent.connectionMode)
    
    if needsReconnect {
        coordinator.reconnect(mode: agent.connectionMode)
    }
    
    // 继续会话设置...
}
```

**最佳实践：**
始终使用 `ChatKitCoordinator` 而不是直接创建 `NeuronRuntime`：

```swift
// ❌ 不要：直接创建会销毁先前的运行时
let runtime = NeuronRuntime(config: config)

// ✅ 要：使用协调器进行安全的生命周期管理
let coordinator = ChatKitCoordinator(config: config)
let runtime = coordinator.runtime
```

---

### 会话不持久化

**症状：**
- 应用重启后会话消失
- 历史记录为空
- 会话未保存

**根本原因：**
未使用 `conversationRepository` 持久化会话。

**解决方案：**
始终将会话持久化到 convstore：

```swift
func createConversation(agent: AgentProfile) {
    guard let runtime = coordinator?.runtime else { return }
    
    let sessionId = UUID()
    let conversation = runtime.openConversation(
        sessionId: sessionId,
        agentId: agent.id
    )
    
    // ✅ 持久化到 convstore
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
            print("持久化失败: \(error)")
        }
    }
}
```

---

### UI 中的消息不更新

**症状：**
- 新消息到达时 UI 不更新
- 消息列表陈旧
- 没有实时更新

**根本原因：**
未观察会话的消息发布者。

**解决方案：**
订阅消息更新：

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

**不要忘记：**
1. 存储 `AnyCancellable`（不要让它被释放）
2. 完成后取消订阅：`cancellables.forEach { $0.cancel() }`

---

### 内存泄漏

**症状：**
- 应用内存随时间增长
- 会话未释放
- 运行时未释放

**根本原因：**
强引用循环或未解绑 UI。

**解决方案：**
销毁会话时始终解绑 UI：

```swift
func deleteConversation(sessionId: UUID) {
    if let conversation = conversations[sessionId] {
        // ✅ 删除前解绑 UI
        conversation.unbindUI()
    }
    conversations.removeValue(forKey: sessionId)
    
    // 取消订阅
    subscriptions[sessionId]?.cancel()
    subscriptions.removeValue(forKey: sessionId)
}
```

**在闭包中使用弱引用：**
```swift
conversation.messagesPublisher
    .sink { [weak self] messages in  // ✅ weak self
        self?.updateUI(with: messages)
    }
    .store(in: &cancellables)
```

---

## 配置问题

### 无效的包名称

**症状：**
- XcodeGen 失败并出现包解析错误
- "Unknown package" 错误

**根本原因：**
`project.yml` 或 `Package.swift` 中的包名称错误。

**解决方案：**
使用 `ChatKit` 作为包名称（不是 `finclip-chatkit`）：

**XcodeGen（project.yml）：**
```yaml
packages:
  ChatKit:  # ✅ 正确
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.3.1
```

**Package.swift：**
```swift
.product(name: "ChatKit", package: "finclip-chatkit")  // ✅ 正确
```

---

### 版本不匹配

**症状：**
- 功能不可用
- API 更改导致编译错误
- 缺少符号

**解决方案：**
确保您使用的是 v0.3.1 或更高版本：

**Package.swift：**
```swift
.package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.3.1")
```

**Podfile：**
```ruby
pod 'ChatKit', :podspec => 'https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/ChatKit.podspec'
```

然后更新：
```bash
# SPM
swift package update

# CocoaPods
pod update ChatKit
```

---

### 缺少资源

**症状：**
- 资源未找到
- 图像缺失
- 访问资源时崩溃

**解决方案：**
SPM 默认自动发现资源。如果需要，显式添加：

```swift
.target(
    name: "YourApp",
    dependencies: [...],
    resources: [.process("Resources")]  // 如果需要
)
```

---

## 平台问题

### "Unsupported platform" 错误

**症状：**
```
error: platform 'macOS' is not supported
```

**根本原因：**
ChatKit 仅支持 iOS 16.0+。

**解决方案：**
确保正确的平台规范：

```swift
platforms: [
    .iOS(.v16)  // ✅ 仅支持 iOS
]
```

---

### 部署目标过低

**症状：**
- 关于不可用 API 的编译错误
- "Minimum deployment target is iOS 16.0"

**解决方案：**
将部署目标设置为 iOS 16.0 或更高：

```yaml
deploymentTarget:
  iOS: "16.0"
```

---

## 调试工具

### 验证框架包

检查框架内部内容：

```bash
# 列出框架
ls -la ChatKit.xcframework/ios-arm64/FinClipChatKit.framework/Frameworks/

# 检查符号
nm ChatKit.xcframework/ios-arm64/FinClipChatKit.framework/FinClipChatKit | grep ChatKitCoordinator
```

### 启用详细日志

```swift
// 添加到 AppDelegate 或 main
print("Runtime: \(coordinator.runtime)")
print("Conversations: \(conversationManager.recordsSnapshot())")
```

### 检查包解析

```bash
# 显示已解析的依赖
swift package show-dependencies

# 描述包
swift package describe
```

---

## 实际案例

### 案例研究 1：ChatKitCoordinator 未找到

**问题：**
AI-Bank 示例构建失败，提示"cannot find type 'ChatKitCoordinator'"。

**调查：**
- 确认源代码中存在 `ChatKitCoordinator`
- 检查它是公共的且在构建配置中
- 发现远程二进制（v0.3.0）不包含它

**解决方案：**
发布了包含 `ChatKitCoordinator` 的重建框架的 v0.3.1。

**教训：**
始终验证远程二进制发布与源代码匹配。

---

### 案例研究 2：会话丢失

**问题：**
Smart-Gov 在切换代理时丢失了所有会话。

**调查：**
- 发现每次切换代理时都在重新创建运行时
- 没有检查是否真的需要重新连接

**解决方案：**
添加了 `isSameConnectionMode` 检查：

```swift
let needsReconnect = coordinator.neuronRuntime == nil ||
                     !coordinator.isSameConnectionMode(agent.connectionMode)
```

**教训：**
仅在连接实际更改时重新创建运行时。

---

## 调试检查清单

遇到问题时，验证：

### 构建时
- [ ] 使用 ChatKit v0.3.1 或更高版本
- [ ] 导入 `FinClipChatKit`，而不是 `ChatKit`
- [ ] 框架搜索路径包含 `FinClipChatKit.framework/Frameworks`
- [ ] Runpath 搜索路径正确
- [ ] 后构建脚本签名嵌套框架
- [ ] 部署目标是 iOS 16.0+
- [ ] 使用正确的包名称（`ChatKit`）

### 运行时
- [ ] 使用 `ChatKitCoordinator`（不是直接 `NeuronRuntime`）
- [ ] 重新连接前检查连接模式
- [ ] 将会话持久化到 convstore
- [ ] 观察消息发布者
- [ ] 销毁会话时解绑 UI
- [ ] 在闭包中使用 `weak self`
- [ ] 清理时取消订阅

---

## 获取帮助

### 自助服务
1. 检查此故障排除指南
2. 查看[入门指南](./getting-started.zh.md)或[快速开始指南](./quick-start.zh.md)
3. 研究可工作的示例：
   - 参见[运行演示](./running-demos.zh.md)了解完整说明
   - `demo-apps/iOS/Simple/` - Swift 示例
   - `demo-apps/iOS/SimpleObjC/` - Objective-C 示例

### 社区支持
1. 搜索 [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)
2. 检查 [Discussions](https://github.com/Geeksfino/finclip-chatkit/discussions)
3. 打开新 issue，包含：
   - ChatKit 版本
   - Xcode 版本
   - 完整错误消息
   - 最小重现步骤

### 报告 Bug
包含：
```
- ChatKit 版本：0.3.1
- Xcode 版本：15.0
- iOS 部署目标：16.0
- 包管理器：SPM / CocoaPods
- 错误消息：[在此粘贴]
- 重现步骤：[在此列出]
```

---

## 有用的命令

```bash
# 清理构建
rm -rf .build ~/Library/Developer/Xcode/DerivedData
xcodebuild clean -scheme YourApp

# 重置 SPM
swift package reset
swift package resolve
swift package update

# 检查依赖
swift package show-dependencies

# 验证框架
unzip -l ChatKit.xcframework.zip | grep ChatKitCoordinator

# 检查符号
nm -gU ChatKit.xcframework/*/FinClipChatKit.framework/FinClipChatKit | grep -i coordinator
```

---

**下一步**：
- **[入门指南](./getting-started.zh.md)** - 学习 ChatKit 模式和最佳实践
- **[快速开始指南](./quick-start.zh.md)** - 最小化骨架代码
- **[Swift 开发者指南](./guides/developer-guide.zh.md)** - 全面的 Swift 模式
- **[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)** - 完整的 Objective-C 指南
