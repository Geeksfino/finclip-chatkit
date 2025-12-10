# ChatKit Android 示例应用

本目录包含一系列全面的示例应用，演示如何使用 ChatKit Android SDK。每个示例都专注于 SDK 的不同方面和使用场景。

[English](README.md)

## 📋 前置要求

- Android Studio Hedgehog (2023.1.1) 或更高版本
- Android 设备或模拟器（API 24+）
- GitHub Personal Access Token（用于下载 SDK 包）
- 可选：ChatKit 后端服务器 URL（或使用 Mock 模式进行离线测试）

## 🔑 GitHub Packages 认证

ChatKit SDK 及其依赖托管在 GitHub Packages 上。构建前需要配置认证。

### 方式 1：环境变量（推荐用于 CI/CD）

```bash
export GITHUB_USERNAME=wubingjie1st
export GITHUB_TOKEN=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
```

### 方式 2：Gradle 属性（推荐用于本地开发）

添加到 `~/.gradle/gradle.properties`：

```properties
gpr.user=wubingjie1st
gpr.key=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
```

## 🚀 快速开始

### 前置条件检查

在开始之前，请确保：

1. **已连接 Android 设备或启动模拟器**
   ```bash
   # 检查设备连接
   adb devices
   # 应该显示已连接的设备，例如：
   # List of devices attached
   # emulator-5554    device
   ```

2. **已配置 GitHub Packages 认证**
   - 方式 1：环境变量
     ```bash
     export GITHUB_USERNAME=wubingjie1st
     export GITHUB_TOKEN=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
     ```
   - 方式 2：Gradle 属性（`~/.gradle/gradle.properties`）
     ```properties
     gpr.user=wubingjie1st
     gpr.key=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
     ```

### 方式 1：使用 Makefile（推荐）

项目提供了 Makefile，可以简化常用的构建、安装和运行操作。

#### 查看所有可用命令

```bash
cd demo-apps/Android
make help
```

#### 常用命令

```bash
# 一键构建、安装并启动应用（最常用）
make run

# 仅构建 APK
make build

# 仅安装应用（需要先构建）
make install

# 仅启动应用（需要先安装）
make start

# 停止运行中的应用
make stop

# 卸载应用
make uninstall

# 清理构建文件
make clean

# 构建 Release 版本
make release

# 检查设备连接状态
make check-device

# 查看应用日志
make logcat

# 运行代码检查
make lint

# 运行单元测试
make test
```

#### 完整工作流程示例

```bash
# 进入项目目录
cd demo-apps/Android

# 检查设备连接
make check-device

# 构建、安装并启动（一条命令）
make run

# 或者分步执行
make build    # 构建 APK
make install  # 安装到设备
make start    # 启动应用
```

### 方式 2：使用命令行（Gradle）

#### 步骤 1：进入项目目录

```bash
cd demo-apps/Android
```

#### 步骤 2：构建项目

```bash
# 构建 Debug APK
./gradlew assembleDebug

# 构建成功后会生成 APK 文件：
# app/build/outputs/apk/debug/app-debug.apk
```

#### 步骤 3：安装到设备

```bash
# 安装 Debug 版本到已连接的设备
./gradlew installDebug

# 或者直接使用 adb 安装已构建的 APK
adb install app/build/outputs/apk/debug/app-debug.apk
```

#### 步骤 4：启动应用

```bash
# 方式 1：使用 adb 启动应用
adb shell am start -n com.finclip.chatkit.examples/.MainActivity

# 方式 2：在设备上手动点击应用图标启动
# 应用名称：ChatKit Examples
```

#### 一键构建、安装并启动

```bash
# 构建、安装并启动应用（一条命令完成）
./gradlew installDebug && adb shell am start -n com.finclip.chatkit.examples/.MainActivity
```

### 方式 3：使用 Android Studio

#### 步骤 1：打开项目

1. 启动 Android Studio
2. 选择 **File → Open**
3. 选择 `demo-apps/Android` 目录
4. 等待 Gradle 同步完成

#### 步骤 2：配置运行设备

1. 在顶部工具栏选择运行配置
2. 选择已连接的设备或模拟器
3. 如果没有设备，点击 **Device Manager** 创建模拟器

#### 步骤 3：运行应用

1. 点击工具栏的 **Run** 按钮（绿色三角形）或按 `Shift + F10`
2. Android Studio 会自动：
   - 构建项目
   - 安装 APK 到设备
   - 启动应用

#### 步骤 4：查看日志

- 在底部 **Logcat** 窗口查看应用日志
- 过滤标签：`ChatKit` 或 `ExamplesApplication`

### 方式 3：直接安装 APK 文件

如果已经构建了 APK 文件：

```bash
# 使用 adb 安装
adb install app/build/outputs/apk/debug/app-debug.apk

# 或者将 APK 传输到设备后，在设备上点击安装
# 1. 将 APK 文件复制到设备
adb push app/build/outputs/apk/debug/app-debug.apk /sdcard/Download/

# 2. 在设备上打开文件管理器，找到 APK 文件并安装
```

### 验证安装

安装成功后，可以通过以下方式验证：

```bash
# 检查应用是否已安装
adb shell pm list packages | grep chatkit
# 应该输出：package:com.finclip.chatkit.examples

# 查看应用信息
adb shell dumpsys package com.finclip.chatkit.examples | grep versionName
# 应该显示版本号：versionName=1.0.0
```

### 配置服务器模式

首次启动应用时，点击右上角的**设置**图标（⚙️）：

1. **Mock 模式**：启用后可在没有真实服务器的情况下进行离线测试
2. **服务器 URL**：未启用 Mock 模式时，输入你的 ChatKit 后端 URL

### 常见问题排查

#### 问题 1：设备未连接

```bash
# 检查设备连接
adb devices

# 如果没有设备，尝试：
# - 检查 USB 调试是否启用
# - 重新连接 USB 线
# - 重启 adb 服务
adb kill-server && adb start-server
```

#### 问题 2：GitHub Packages 认证失败

**错误信息**：`401 Unauthorized` 或 `Could not resolve dependency`

**解决方案**：
```bash
# 检查环境变量
echo $GITHUB_USERNAME
echo $GITHUB_TOKEN

# 或检查 Gradle 属性
cat ~/.gradle/gradle.properties | grep gpr

# 确保 Token 具有 read:packages 权限
```

#### 问题 3：构建失败

```bash
# 清理构建缓存
./gradlew clean

# 重新构建
./gradlew assembleDebug

# 查看详细错误信息
./gradlew assembleDebug --stacktrace
```

#### 问题 4：应用启动失败

```bash
# 查看应用日志
adb logcat | grep -i chatkit

# 查看崩溃日志
adb logcat | grep -i "AndroidRuntime"

# 清除应用数据并重新安装
adb uninstall com.finclip.chatkit.examples
./gradlew installDebug
```

---

## 📱 示例列表

| # | 示例 | 描述 | 主要 API |
|---|------|------|----------|
| 1 | [简单聊天](#1-简单聊天) | 最小化聊天设置 | `ChatKit.createCoordinator()`, `ChatFragment` |
| 2 | [配置示例](#2-配置示例) | 自定义聊天 UI | `ChatKitConfiguration`, `StatusBannerStyle` |
| 3 | [会话管理](#3-会话管理) | 增删改查操作 | `ChatKitConversationManager`, `ConversationListFragment` |
| 4 | [上下文提供者](#4-上下文提供者) | 添加设备/网络上下文 | `ConversationContextItem`, `ContextAugmenter` |
| 5 | [Compose 示例](#5-compose-示例) | Jetpack Compose 集成 | `ChatKitChatView`, `ConnectionStatusBanner` |
| 6 | [完整功能](#6-完整功能) | 所有功能组合 | 完整 SDK 集成 |
| 7 | [高级 API](#7-高级-api) | 底层 API 和自定义 | `NeuronRuntime`, 自定义提供者 |

---

## 📦 依赖包

此示例应用使用以下来自 GitHub Packages 的 SDK：

| 包名 | 版本 | 描述 |
|------|------|------|
| `com.finclip:chatkit` | 1.0.1 | ChatKit Android SDK |
| `com.finclip:convoui` | 1.0.0 | UI 组件（传递依赖） |
| `com.finclip:neuronkit` | 1.0.1 | 核心运行时（传递依赖） |
| `com.finclip:sandbox` | 1.0.0 | 策略引擎（传递依赖） |
| `com.finclip:convstore` | 1.0.0 | 消息存储（传递依赖） |

> 注意：只有 `chatkit` 是直接依赖。其他 SDK 是传递依赖。

---

## 1. 简单聊天

**文件**: `app/src/main/java/com/finclip/chatkit/examples/simple/SimpleChatActivity.kt`

集成 ChatKit 的最简单方式 - 只需几行代码即可获得一个可用的聊天界面。

### 功能特性
- 基本聊天功能
- 最小化配置
- 使用默认设置

### 使用的 SDK API

```kotlin
// 创建协调器
val coordinator = ChatKit.createCoordinator(
    context = this,
    serverURL = "wss://your-server.com",
    userId = "user-123"
)

// 开始会话
val (record, conversation) = coordinator.startConversation(
    agentId = agentId,
    title = "Simple Chat"
)

// 显示聊天 UI
val fragment = ChatFragment.newInstance(record.id)
supportFragmentManager.beginTransaction()
    .replace(R.id.fragmentContainer, fragment)
    .commit()
```

### 测试步骤

1. 启动应用 → 选择"1. Simple Chat"
2. 等待聊天界面加载
3. 输入消息并发送
4. 验证消息出现在聊天中
5. 验证收到 AI 响应（Mock 模式：立即响应；服务器模式：可能需要几秒钟）

---

## 2. 配置示例

**文件**: `app/src/main/java/com/finclip/chatkit/examples/config/ConfigurationActivity.kt`

演示如何通过各种配置选项自定义聊天体验。

### 功能特性
- 自定义欢迎消息
- 带回调的提示启动器
- 自定义状态横幅样式
- 输入框自定义
- 分页设置

---

## 3. 会话管理

**文件**: `app/src/main/java/com/finclip/chatkit/examples/conversation/ConversationManagementActivity.kt`

完整演示会话生命周期管理。

### 功能特性
- 创建新会话
- 列出所有会话
- 搜索会话
- 删除会话（滑动或批量）
- 置顶/取消置顶会话
- 查看历史消息

---

## 4. 上下文提供者

**文件**: `app/src/main/java/com/finclip/chatkit/examples/context/ContextProviderActivity.kt`

展示如何用设备和网络上下文信息丰富消息。

### 功能特性
- 设备状态上下文（电池、系统版本、型号）
- 网络状态上下文（WiFi/蜂窝网络）
- 消息上下文增强
- 自定义上下文查询提示

---

## 5. Compose 示例

**文件**: `app/src/main/java/com/finclip/chatkit/examples/compose/ComposeExampleActivity.kt`

演示 Jetpack Compose 与 ChatKit 的集成。

### 功能特性
- 纯 Compose UI
- Compose 聊天视图
- 连接状态横幅（Compose）
- Compose 中的错误处理
- 加载状态

---

## 6. 完整功能

**文件**: `app/src/main/java/com/finclip/chatkit/examples/full/FullFeatureActivity.kt`

组合所有 SDK 功能的综合示例。

### 功能特性
- 所有配置选项
- 带文件处理器的日志
- 完整配置的会话列表
- 错误处理演示
- 连接状态监控

---

## 7. 高级 API

**文件**: `app/src/main/java/com/finclip/chatkit/examples/advanced/AdvancedApiActivity.kt`

演示底层 API 和高级自定义。

### 功能特性
- 框架信息显示
- 自定义标题提供者
- 自定义连接状态提供者
- 连接模式切换
- 提示启动器工厂
- 最小化/紧凑配置
- 自定义错误处理器
- 底层运行时 API

---

## 🔧 Mock 模式

示例包含完整的 Mock 实现，用于离线开发：

### MockRuntime

**文件**: `app/src/main/java/com/finclip/chatkit/examples/mock/MockRuntime.kt`

- 无需服务器即可模拟 AI 响应
- 支持所有运行时操作
- 上下文感知响应（识别 "你好"、"代码"、"帮助" 等）
- 包含 mock ConversationRepository

### 切换模式

```kotlin
// 在 AppSettings 中
AppSettings.useMock = true  // 启用 mock 模式
AppSettings.useMock = false // 使用真实服务器

// ChatKitHelper 自动选择正确的实现
val coordinator = ChatKitHelper.createCoordinator(context)
```

---

## 📁 项目结构

```
Android/
├── app/
│   └── src/main/java/com/finclip/chatkit/examples/
│       ├── MainActivity.kt              # 示例列表启动器
│       ├── ExamplesApplication.kt       # Application 类
│       │
│       ├── simple/
│       │   └── SimpleChatActivity.kt    # 基本聊天示例
│       │
│       ├── config/
│       │   └── ConfigurationActivity.kt # 配置示例
│       │
│       ├── conversation/
│       │   └── ConversationManagementActivity.kt  # CRUD 示例
│       │
│       ├── context/
│       │   └── ContextProviderActivity.kt  # 上下文提供者示例
│       │
│       ├── compose/
│       │   └── ComposeExampleActivity.kt   # Jetpack Compose 示例
│       │
│       ├── full/
│       │   └── FullFeatureActivity.kt   # 完整功能示例
│       │
│       ├── advanced/
│       │   └── AdvancedApiActivity.kt   # 高级 API 示例
│       │
│       ├── mock/
│       │   └── MockRuntime.kt           # 离线 mock 实现
│       │
│       ├── settings/
│       │   ├── AppSettings.kt           # 应用配置
│       │   └── ChatKitHelper.kt         # 协调器创建辅助类
│       │
│       └── ui/theme/
│           └── Theme.kt                 # Compose 主题
│
├── build.gradle.kts                     # 根构建配置
├── settings.gradle.kts                  # 设置（含 GitHub Packages 仓库）
├── gradle.properties                    # Gradle 属性
└── gradle/wrapper/                      # Gradle wrapper
```

---

## 🔗 相关资源

- [finclip-chatkit 文档](../../docs/)
- [ChatKit Android SDK](https://github.com/Geeksfino/chatkit-android)
- [NeuronKit Android SDK](https://github.com/Geeksfino/neuronkit-android)
- [ConvoUI Android SDK](https://github.com/Geeksfino/ConvoUI-Android)
