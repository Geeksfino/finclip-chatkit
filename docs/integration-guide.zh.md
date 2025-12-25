# ChatKit 集成指南

本指南涵盖 ChatKit 的特定集成场景和部署选项。

> 📚 **要学习如何使用 ChatKit 构建应用**，请参见[入门指南](./getting-started.zh.md)或[快速开始指南](./quick-start.zh.md)。
> 
> 🔧 **要设置构建工具**，请参见[构建工具指南](./build-tooling.zh.md)了解 Makefile、XcodeGen 和可重现构建。
> 
> 📖 **要查看全面开发指南**，请参见[Swift 开发者指南](./guides/developer-guide.zh.md)或[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)。

---

## 目录

1. [包管理器设置](#包管理器设置)
2. [CocoaPods 集成](#cocoapods-集成)
3. [手动 XCFramework 集成](#手动-xcframework)
4. [构建设置和配置](#构建设置)
5. [部署和分发](#部署)

---

## 包管理器设置

### Swift Package Manager（推荐）

#### 方法 1：Package.swift

对于 Swift Package 项目：

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
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

#### 方法 2：Xcode UI

对于 Xcode 项目：

1. **File → Add Package Dependencies...**
2. 输入仓库 URL：`https://github.com/Geeksfino/finclip-chatkit.git`
3. 选择版本：`0.7.4` 或更高
4. 选择 `ChatKit` 产品
5. 添加到您的目标

#### 方法 3：XcodeGen（project.yml）

对于使用 XcodeGen 的项目：

```yaml
name: YourApp
options:
  bundleIdPrefix: com.yourcompany
  deploymentTarget:
    iOS: "16.0"

packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.7.4

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

## CocoaPods 集成

### 基本 Podfile

```ruby
platform :ios, '16.0'
use_frameworks!

target 'YourApp' do
  pod 'ChatKit', :podspec => 'https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/ChatKit.podspec'
end
```

> **注意**：我们使用直接 podspec URL，因为 CocoaPods trunk 上的 "ChatKit" 名称已被另一个项目占用。

### 安装和构建

```bash
# 安装依赖
pod install

# 打开工作区（不是 .xcodeproj！）
open YourApp.xcworkspace
```

### 更新 ChatKit

```bash
# 更新到最新版本
pod update ChatKit

# 或更新所有 pod
pod update
```

---

## 手动 XCFramework

对于无法使用包管理器的项目：

### 步骤 1：下载

从 [GitHub Releases](https://github.com/Geeksfino/finclip-chatkit/releases) 下载 `ChatKit.xcframework.zip`：

```bash
curl -LO https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.4/ChatKit.xcframework.zip
unzip ChatKit.xcframework.zip
```

### 步骤 2：添加到 Xcode

1. 将 `ChatKit.xcframework` 拖入您的 Xcode 项目
2. 选择 **Copy items if needed**
3. 添加到您的应用目标

### 步骤 3：嵌入框架

在 **General → Frameworks, Libraries, and Embedded Content** 中：
- 选择 `ChatKit.xcframework`
- 设置为 **Embed & Sign**

### 步骤 4：导入

```swift
import FinClipChatKit
```

---

## 构建设置

### 必需设置

ChatKit 需要特定的构建设置以正确解析框架。

#### Framework Search Paths

在目标的 **Build Settings** 中添加这些：

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

### XcodeGen 配置

如果使用 XcodeGen，添加到您的 `project.yml`：

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

### 代码签名嵌套框架

添加后构建脚本以签名嵌套框架：

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

## 部署

### App Store 提交

ChatKit 已准备好提交 App Store。无需特殊步骤。

**重要**：确保您使用 **v0.7.4 或更高版本**，其中包含所有嵌套框架的正确代码签名。

### TestFlight Beta

开箱即用。像往常一样上传您的 IPA：

```bash
xcodebuild archive -scheme YourApp -archivePath build/YourApp.xcarchive
xcodebuild -exportArchive -archivePath build/YourApp.xcarchive -exportPath build/YourApp.ipa -exportOptionsPlist ExportOptions.plist
```

### Ad-Hoc 分发

与 App Store 构建相同。确保正确的配置文件。

### 企业分发

完全支持。使用您的企业证书进行代码签名。

---

## 平台支持

| 平台 | 支持 | 最低版本 |
|----------|-----------|----------------|
| iOS | ✅ | 16.0+ |
| iPadOS | ✅ | 16.0+ |
| macOS | ❌ | N/A |
| tvOS | ❌ | N/A |
| watchOS | ❌ | N/A |

---

## 版本要求

| 工具 | 最低版本 |
|------|----------------|
| Xcode | 15.0 |
| Swift | 5.9 |
| iOS | 16.0 |

---

## 依赖树

ChatKit 捆绑这些框架：

```
ChatKit.xcframework
├── FinClipChatKit.framework（主框架）
│   ├── NeuronKit.framework
│   ├── ConvoUI.framework
│   ├── SandboxSDK.framework
│   └── convstore.framework（convstorelib）
```

所有框架都已嵌入和签名。无需额外设置。

---

## 集成故障排除

### "Framework not found: FinClipChatKit"（未找到框架：FinClipChatKit）

**解决方案**：检查框架搜索路径（参见[构建设置](#构建设置)）

### "Library not loaded: @rpath/NeuronKit.framework"（库未加载：@rpath/NeuronKit.framework）

**解决方案**：
1. 检查 runpath 搜索路径包含 `@loader_path/Frameworks/FinClipChatKit.framework/Frameworks`
2. 确保嵌套框架已签名（参见上面的后构建脚本）

### "Module 'ChatKit' not found"（未找到模块 'ChatKit'）

**解决方案**：
1. 确保您导入的是 `FinClipChatKit`，而不是 `ChatKit`
   ```swift
   import FinClipChatKit  // ✅ 正确
   import ChatKit         // ❌ 错误
   ```
2. 清理构建文件夹：**Product → Clean Build Folder**（⇧⌘K）

### SPM 缓存问题

**解决方案**：重置包缓存
```bash
# 清除 SPM 缓存
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf .build

# 再次解析包
swift package resolve
```

### CocoaPods 问题

**解决方案**：更新 CocoaPods 并清除缓存
```bash
# 更新 CocoaPods
sudo gem install cocoapods

# 清除缓存
pod cache clean --all
pod deintegrate
pod install
```

---

## 迁移指南

### 从 v0.2.x 到 v0.3.x

**破坏性变更：**
- `ChatKitCoordinator` 现在是推荐的入口点
- 不鼓励直接创建 `NeuronRuntime`

**迁移步骤：**

1. 更新依赖版本：
   ```swift
   .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.4")
   ```

2. 替换直接运行时创建：
   ```swift
   // ❌ 旧方式（v0.2.x）
   let runtime = NeuronRuntime(config: config)
   
   // ✅ 新方式（v0.3.x）
   let coordinator = ChatKitCoordinator(config: config)
   let runtime = coordinator.runtime
   ```

3. 保持协调器存活：
   ```swift
   class MyViewController: UIViewController {
       private var coordinator: ChatKitCoordinator?  // 存储它！
       
       func setup() {
           coordinator = ChatKitCoordinator(config: config)
           // 现在使用 coordinator.runtime
       }
   }
   ```

---

## CI/CD 集成

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

## 高级主题

### 使用自定义 ChatKit 构建进行本地开发

要使用本地 ChatKit 构建进行开发：

```swift
// 在 Package.swift 中
.package(path: "../chatkit/.dist")
```

参见 [AI-Bank 示例](../demo-apps/iOS/AI-Bank) 作为参考。

### 多个 ChatKit 版本

不推荐。如果绝对需要：
1. 使用不同的产品名称
2. 为您的导入添加命名空间
3. 确保没有符号冲突

### 自定义框架捆绑

如果将 ChatKit 捆绑到您自己的框架中：
1. 重新导出公共符号
2. 维护搜索路径
3. 签名所有嵌套框架

---

## 参考示例

### 最小 SPM 设置

参见：`demo-apps/iOS/AI-Bank/Package.swift`

### 完整 XcodeGen 设置

参见：`demo-apps/iOS/Smart-Gov/project.yml`（简化之前）

### CocoaPods 设置

参见：`demo-apps/iOS/Smart-Gov/Podfile`

---

## 支持

对于集成问题：
1. 检查[故障排除指南](./troubleshooting.zh.md)
2. 查看[运行演示](./running-demos.zh.md)了解示例应用
3. 打开 [GitHub Issue](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**下一步**：
- **[入门指南](./getting-started.zh.md)** - 学习如何使用 ChatKit 构建应用
- **[快速开始指南](./quick-start.zh.md)** - 最小化骨架代码
- **[Swift 开发者指南](./guides/developer-guide.zh.md)** - 全面的 Swift 模式
- **[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)** - 完整的 Objective-C 指南
