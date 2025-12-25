# 构建工具指南

本指南涵盖了可复现构建 ChatKit 应用的工具和工作流程。这些工具确保跨不同环境的一致构建，对于 AI 代理和自动化工作流程至关重要。

---

## 概述

ChatKit 演示应用使用标准化的构建系统：

- **XcodeGen** - 从 YAML 配置生成 Xcode 项目
- **Makefile** - 标准化的构建命令
- **project.yml** - 项目配置（依赖项、设置、源代码）
- **xcrun simctl** - 模拟器管理

这种方法提供：
- ✅ 可复现的构建
- ✅ 版本控制的项目配置
- ✅ 简单的环境设置
- ✅ AI 代理友好的工作流程

---

## 前置条件

### 必需工具

```bash
# 安装 XcodeGen
brew install xcodegen

# 验证安装
xcodegen --version
```

### Xcode 命令行工具

```bash
# 如果尚未安装，则安装
xcode-select --install
```

---

## XcodeGen

### 什么是 XcodeGen？

XcodeGen 从 YAML 文件（`project.yml`）生成 Xcode 项目。这允许：
- 版本控制项目结构
- 可复现的项目生成
- 避免 Xcode 项目合并冲突
- 一致的项目配置

### 基本用法

```bash
# 从 project.yml 生成 Xcode 项目
xcodegen generate --spec project.yml

# 或使用 Makefile 目标
make generate
```

### 安装

```bash
brew install xcodegen
```

---

## project.yml 结构

`project.yml` 文件定义了整个 Xcode 项目结构。

### 基本结构

```yaml
name: MyChatApp
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"

schemes:
  MyChatApp:
    build:
      targets:
        MyChatApp: all
    run:
      config: Debug

packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.7.4

targets:
  MyChatApp:
    type: application
    platform: iOS
    sources:
      - path: App/App
      - path: App/ViewControllers
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.mychatapp
      PRODUCT_NAME: MyChatApp
      INFOPLIST_FILE: App/App/Info.plist
      ENABLE_BITCODE: NO
    dependencies:
      - package: ChatKit
```

### 关键部分

#### 1. 项目元数据

```yaml
name: MyChatApp
options:
  bundleIdPrefix: com.example
  deploymentTarget:
    iOS: "16.0"
```

#### 2. 包依赖项

```yaml
packages:
  ChatKit:
    url: https://github.com/Geeksfino/finclip-chatkit.git
    from: 0.7.4
```

#### 3. 目标配置

```yaml
targets:
  MyChatApp:
    type: application
    platform: iOS
    sources:
      - path: App/App
      - path: App/ViewControllers
    settings:
      PRODUCT_BUNDLE_IDENTIFIER: com.example.mychatapp
      INFOPLIST_FILE: App/App/Info.plist
    dependencies:
      - package: ChatKit
```

#### 4. 框架搜索路径

对于 ChatKit 的嵌套框架：

```yaml
settings:
  FRAMEWORK_SEARCH_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  FRAMEWORK_SEARCH_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  LD_RUNPATH_SEARCH_PATHS: $(inherited) @executable_path/Frameworks @loader_path/Frameworks @loader_path/Frameworks/FinClipChatKit.framework/Frameworks
  SWIFT_INCLUDE_PATHS[sdk=iphoneos*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
  SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]: $(inherited) $(BUILT_PRODUCTS_DIR)/FinClipChatKit.framework/Frameworks
```

#### 5. 构建后脚本

用于签名嵌套框架：

```yaml
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

### 完整示例

参见 `demo-apps/iOS/Simple/project.yml` 获取完整的工作示例。

---

## Makefile 模式

### 标准 Makefile 结构

```makefile
PROJECT_NAME=MyChatApp
PROJECT_FILE=$(PROJECT_NAME).xcodeproj
SIMULATOR_DEVICE?=iPhone 17
SIMULATOR_DESTINATION?=platform=iOS Simulator,name=$(SIMULATOR_DEVICE)

.PHONY: generate open clean deep-clean run

generate:
	@if ! command -v xcodegen >/dev/null 2>&1; then \
		echo "❌ XcodeGen not installed. Install with 'brew install xcodegen'."; \
		exit 1; \
	fi
	@echo "🔧 Generating Xcode project..."
	xcodegen generate --spec project.yml
	@echo "✅ Project generated: $(PROJECT_FILE)"

open: generate
	@echo "📂 Opening $(PROJECT_FILE)..."
	xed "$(PROJECT_FILE)"

run: generate
	@echo "🚀 Building and running $(PROJECT_NAME) on iOS simulator..."
	xcodebuild \
	  -project "$(PROJECT_FILE)" \
	  -scheme "$(PROJECT_NAME)" \
	  -destination '$(SIMULATOR_DESTINATION)' \
	  -configuration Debug \
	  -derivedDataPath build/DerivedData \
	  build
	APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/$(PROJECT_NAME).app"; \
	if [ ! -d "$$APP_PATH" ]; then \
		echo "❌ Built app not found at $$APP_PATH"; \
		exit 1; \
	fi; \
	xcrun simctl boot "$(SIMULATOR_DEVICE)" >/dev/null 2>&1 || true; \
	xcrun simctl install booted "$$APP_PATH"; \
	xcrun simctl launch booted com.example.mychatapp
	@echo "✅ $(PROJECT_NAME) launched on simulator"

clean:
	@echo "🧹 Cleaning generated project and local build outputs..."
	rm -rf "$(PROJECT_FILE)" "$(PROJECT_NAME).xcworkspace"
	rm -rf build
	@echo "✅ Clean complete"

deep-clean: clean
	@echo "🧼 Removing simulator-installed app (if any)..."
	- xcrun simctl uninstall booted com.example.mychatapp >/dev/null 2>&1 || true
	@echo "✅ Deep clean complete"
```

### Makefile 目标

#### `make generate`
从 `project.yml` 生成 Xcode 项目。

**功能**：
1. 检查是否安装了 XcodeGen
2. 运行 `xcodegen generate --spec project.yml`
3. 创建 `.xcodeproj` 文件

**预期输出**：
```
🔧 Generating Xcode project...
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at /path/to/MyChatApp.xcodeproj
✅ Project generated: MyChatApp.xcodeproj
```

#### `make open`
生成项目（如果需要）并在 Xcode 中打开它。

**功能**：
1. 如果项目不存在，调用 `make generate`
2. 使用 `xed`（Xcode 命令行工具）打开项目

#### `make run`
在模拟器上构建并运行应用。

**功能**：
1. 生成项目（如果需要）
2. 使用 `xcodebuild` 构建
3. 启动模拟器（如果未运行）
4. 安装应用
5. 启动应用

**预期输出**：
```
🚀 Building and running MyChatApp on iOS simulator...
[构建输出...]
✅ MyChatApp launched on simulator
```

#### `make clean`
删除生成的项目和构建工件。

**删除内容**：
- `.xcodeproj` 目录
- `.xcworkspace` 目录
- `build/` 目录

#### `make deep-clean`
删除 `clean` 的所有内容，外加从模拟器卸载应用。

---

## xcodebuild

### 构建项目

```bash
# 为模拟器构建
xcodebuild \
  -project MyChatApp.xcodeproj \
  -scheme MyChatApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  build
```

### 关键参数

- `-project`：`.xcodeproj` 文件的路径
- `-scheme`：方案名称（通常与项目名称匹配）
- `-destination`：模拟器或设备目标
- `-configuration`：Debug 或 Release
- `-derivedDataPath`：存储构建工件的位置

### 常见目标

```bash
# iPhone 17 模拟器
-destination 'platform=iOS Simulator,name=iPhone 17'

# 任何可用的 iPhone 模拟器
-destination 'platform=iOS Simulator,name=iPhone'

# 物理设备（需要连接的设备）
-destination 'platform=iOS,id=<device-id>'
```

---

## xcrun simctl

### 模拟器管理

#### 列出可用模拟器

```bash
xcrun simctl list devices available
```

**预期输出**：
```
== Devices ==
iPhone 17 (12345678-1234-1234-1234-123456789012) (Shutdown)
iPhone 16 Pro (87654321-4321-4321-4321-210987654321) (Shutdown)
```

#### 启动模拟器

```bash
xcrun simctl boot "iPhone 17"
```

**注意**：如果尚未运行，则启动模拟器。使用 `> /dev/null 2>&1 || true` 来抑制已启动时的错误。

#### 安装应用

```bash
xcrun simctl install booted /path/to/MyChatApp.app
```

**注意**：`booted` 指当前已启动的模拟器。

#### 启动应用

```bash
xcrun simctl launch booted com.example.mychatapp
```

**注意**：需要来自 `Info.plist` 或 `PRODUCT_BUNDLE_IDENTIFIER` 设置的 bundle identifier。

#### 卸载应用

```bash
xcrun simctl uninstall booted com.example.mychatapp
```

#### 关闭模拟器

```bash
xcrun simctl shutdown booted
```

---

## 可复现构建工作流程

### 分步过程

#### 1. 环境设置

```bash
# 安装 XcodeGen
brew install xcodegen

# 验证工具
xcodegen --version
xcodebuild -version
xcrun simctl list devices
```

#### 2. 生成项目

```bash
cd /path/to/your/app
make generate
```

**预期结果**：创建 `.xcodeproj` 文件

#### 3. 构建应用

```bash
make run
```

**发生什么**：
1. 生成项目（如果需要）
2. 使用 xcodebuild 构建应用
3. 启动模拟器（如果需要）
4. 安装应用
5. 启动应用

#### 4. 清理

```bash
make clean        # 删除构建工件
make deep-clean   # 同时从模拟器卸载
```

### 完整工作流程示例

```bash
# 1. 导航到项目
cd demo-apps/iOS/Simple

# 2. 生成 Xcode 项目
make generate

# 3. 构建并运行
make run

# 4. 完成后清理
make deep-clean
```

---

## AI 代理工作流程

对于 AI 代理或自动化系统，使用这个结构化工作流程：

### 1. 检查前置条件

```bash
# 检查 XcodeGen
if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Installing XcodeGen..."
    brew install xcodegen
fi

# 检查 Xcode
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Xcode not found. Please install Xcode."
    exit 1
fi
```

### 2. 生成项目

```bash
cd /path/to/project
xcodegen generate --spec project.yml
```

**预期**：创建 `.xcodeproj`，退出代码 0

### 3. 构建项目

```bash
xcodebuild \
  -project MyChatApp.xcodeproj \
  -scheme MyChatApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  -derivedDataPath build/DerivedData \
  build
```

**预期**：构建成功，退出代码 0

### 4. 验证构建输出

```bash
APP_PATH="build/DerivedData/Build/Products/Debug-iphonesimulator/MyChatApp.app"
if [ ! -d "$APP_PATH" ]; then
    echo "Build failed: app not found"
    exit 1
fi
```

### 5. 在模拟器上运行

```bash
# 启动模拟器
xcrun simctl boot "iPhone 17" >/dev/null 2>&1 || true

# 安装应用
xcrun simctl install booted "$APP_PATH"

# 启动应用
xcrun simctl launch booted com.example.mychatapp
```

---

## 故障排除

### XcodeGen 未找到

**错误**：`xcodegen: command not found`

**解决方案**：
```bash
brew install xcodegen
```

### 项目生成失败

**错误**：`Error: ...`

**检查**：
1. `project.yml` 语法是有效的 YAML
2. 所有引用的源路径都存在
3. 包 URL 可访问

**调试**：
```bash
xcodegen generate --spec project.yml --verbose
```

### 构建失败

**错误**：`BUILD FAILED`

**检查**：
1. 包依赖项已解决：`swift package resolve`
2. `project.yml` 中的框架搜索路径正确
3. 代码签名设置有效

**调试**：
```bash
xcodebuild -project MyChatApp.xcodeproj -scheme MyChatApp build 2>&1 | grep error
```

### 找不到模拟器

**错误**：`Unable to find a destination matching the provided destination specifier`

**解决方案**：
```bash
# 列出可用模拟器
xcrun simctl list devices available

# 使用列表中的确切名称
xcrun simctl boot "iPhone 17"
```

### 应用无法启动

**错误**：应用安装但不启动

**检查**：
1. Bundle identifier 匹配：`xcrun simctl launch booted <bundle-id>`
2. 应用已正确签名
3. 模拟器已启动：`xcrun simctl list devices | grep Booted`

---

## 最佳实践

### 1. 版本控制

**提交**：
- ✅ `project.yml`
- ✅ `Makefile`
- ✅ `Package.swift`（如果使用）
- ✅ 源代码

**不要提交**：
- ❌ `.xcodeproj`（生成的）
- ❌ `build/` 目录
- ❌ `.xcworkspace`（如果生成）

### 2. 一致的设备名称

在团队中使用一致的模拟器设备名称：

```makefile
SIMULATOR_DEVICE?=iPhone 17
```

### 3. 构建工件

将构建工件存储在 `build/` 目录中（已忽略）：

```makefile
-derivedDataPath build/DerivedData
```

### 4. 错误处理

Makefile 目标应检查错误：

```makefile
if [ ! -d "$$APP_PATH" ]; then
    echo "❌ Build failed: app not found";
    exit 1;
fi
```

---

## 参考示例

### 完整的 project.yml
参见：`demo-apps/iOS/Simple/project.yml`

### 完整的 Makefile
参见：`demo-apps/iOS/Simple/Makefile`

### Objective-C 示例
参见：`demo-apps/iOS/SimpleObjC/` 获取 Objective-C 特定模式

---

## 下一步

- **[快速开始指南](./quick-start.zh.md)** - 构建您的第一个应用
- **[入门指南](./getting-started.zh.md)** - 详细演练
- **[组件嵌入指南](./component-embedding.zh.md)** - 学习组件使用
- **[Swift 开发者指南](./guides/developer-guide.zh.md)** - 全面的 Swift 模式
- **[Objective-C 开发者指南](./guides/objective-c-guide.zh.md)** - 完整的 Objective-C 指南

---

**提示**：在构建之前始终使用 `make generate`。永远不要直接编辑 `.xcodeproj` - 改为编辑 `project.yml`。
