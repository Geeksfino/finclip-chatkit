# 运行示例应用

快速指南，让 ChatKit 示例应用与后端服务器一起运行。

## TL;DR - 5 分钟快速开始

> **注意：** 默认情况下，服务器使用**模拟响应**（预脚本场景）。要使用**真实 AI**（DeepSeek 或其他 LLM 提供商），请参见下面的[使用真实 AI](#使用真实-aideepseek-或其他-llm-提供商)。

### 终端 1：启动后端服务器

```bash
cd demo-apps/server/agui-test-server
npm install  # 仅首次需要
npm run dev  # 默认使用模拟响应
```

等待：`✓ Server listening at http://0.0.0.0:3000`

### 终端 2：运行 iOS 示例

**Swift 示例：**
```bash
cd demo-apps/iOS/Simple
make run
```

**Objective-C 示例：**
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

就是这样！应用将在 iOS 模拟器上启动并连接到服务器。

---

## 详细说明

### 步骤 1：安装前置条件

#### 后端服务器
- **Node.js 20+**：[下载](https://nodejs.org/) 或通过 Homebrew 安装：
  ```bash
  brew install node
  ```

#### iOS 应用
- **Xcode 15.0+**：[从 Mac App Store 下载](https://apps.apple.com/us/app/xcode/id497799835)
- **XcodeGen**：
  ```bash
  brew install xcodegen
  ```

### 步骤 2：启动后端服务器

后端服务器提供响应聊天消息的 AI 代理。

**两种可用模式：**
- **模拟模式**（默认）：使用预脚本场景，无需 API 密钥
- **LLM 模式**：使用真实 AI 提供商（DeepSeek、OpenAI 等）- 需要配置

#### 以模拟模式启动（默认）

```bash
# 导航到服务器目录
cd demo-apps/server/agui-test-server

# 安装依赖（仅首次需要）
npm install

# 以模拟模式启动（预脚本响应）
npm run dev
```

#### 以 LLM 模式启动（真实 AI）

首先配置您的 LLM 提供商（参见[使用真实 AI](#使用真实-aideepseek-或其他-llm-提供商)），然后：

```bash
# 启用 LLM 提供商启动
npm run dev --use-llm
```

**预期输出：**
```
[11:43:41.000] INFO: Starting AG-UI test server...
[11:43:41.123] INFO: Agent mode: emulated  # 如果使用 --use-llm 则为 "llm"
[11:43:41.456] INFO: Server listening at http://0.0.0.0:3000
```

**当您看到以下内容时服务器已就绪**：`✓ Server listening`

**不要关闭此终端** - 在使用 iOS 应用时保持服务器运行。

### 步骤 3：运行 iOS 示例

打开**新终端窗口**并选择一个示例：

#### 选项 A：Simple（Swift）- 推荐

```bash
cd demo-apps/iOS/Simple

# 从 project.yml 生成 Xcode 项目
make generate

# 在模拟器上构建和运行
make run
```

**替代方案** - 在 Xcode 中打开：
```bash
make open
# 然后按 Cmd+R 构建并运行
```

#### 选项 B：SimpleObjC（Objective-C）

```bash
cd demo-apps/iOS/SimpleObjC

# 从 project.yml 生成 Xcode 项目
make generate

# 在模拟器上构建和运行
make run
```

### 步骤 4：使用应用

**Simple（Swift）：**
1. 点击汉堡菜单（≡）打开抽屉
2. 点击"+"创建新会话
3. 输入"Hello"并点击发送
4. 代理自动响应

**SimpleObjC（Objective-C）：**
1. 在连接屏幕上，点击"Connect"
2. 在会话列表中点击"+"
3. 输入"Hello"并点击发送
4. 代理自动响应

---

## 故障排除

### 服务器问题

#### "Port already in use"（端口已被使用）
```bash
# 查找使用端口 3000 的进程
lsof -i :3000

# 终止进程（替换 PID）
kill -9 PID
```

或在 `demo-apps/server/agui-test-server/.env` 中使用不同的端口：
```env
PORT=3001
```

#### "Command not found: npm"（命令未找到：npm）
安装 Node.js：
```bash
brew install node
```

#### 依赖无法安装
```bash
cd demo-apps/server/agui-test-server
rm -rf node_modules package-lock.json
npm install
```

### iOS 应用问题

#### "Command not found: xcodegen"（命令未找到：xcodegen）
```bash
brew install xcodegen
```

#### "Build failed"（构建失败）或"Scheme not found"（方案未找到）
```bash
cd demo-apps/iOS/Simple  # 或 SimpleObjC
make clean
make generate
make run
```

#### "Cannot connect to server"（无法连接到服务器）

1. **验证服务器正在运行：**
   ```bash
   curl http://localhost:3000/health
   ```
   应返回：`{"status":"ok",...}`

2. **检查应用服务器 URL**（应为 `http://127.0.0.1:3000/agent`）
   - **Simple**：参见 `App/App/AppConfig.swift`
   - **SimpleObjC**：参见 `App/Coordinators/ChatCoordinator.m`

3. **如果使用物理设备**，将 URL 更改为您的 Mac IP：
   ```swift
   // 查找您的 Mac IP：系统设置 → 网络 → Wi-Fi → 详细信息
   http://192.168.1.100:3000/agent  // 替换为您的 IP
   ```

#### "Simulator not found: iPhone 17"（模拟器未找到：iPhone 17）
模拟器设备不存在。列出可用设备：
```bash
xcrun simctl list devices available
```

然后更新 Makefile 或使用不同的设备运行：
```bash
make run SIMULATOR_DEVICE="iPhone 16"
```

---

## 高级用法

### 使用真实 AI（DeepSeek 或其他 LLM 提供商）

要使用真实 AI 而不是模拟响应，您需要配置 LLM 提供商。

**我们推荐使用 DeepSeek**，因为它以低成本提供高质量响应。

#### 步骤 1：获取 API 密钥

从 [DeepSeek 平台](https://platform.deepseek.com/)（或您首选的 OpenAI 兼容提供商）获取 API 密钥。

#### 步骤 2：配置环境

复制示例配置文件：

```bash
cd demo-apps/server/agui-test-server
cp .env.example .env
```

然后使用您的首选配置编辑 `.env`：

**选项 A：直接使用 DeepSeek（推荐）**
```env
# 取消注释这些行：
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=sk-your-deepseek-key-here
DEEPSEEK_MODEL=deepseek-chat
```

**选项 B：通过 LiteLLM（支持多个提供商）**
```env
LLM_PROVIDER=litellm
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_MODEL=deepseek-chat
LITELLM_API_KEY=your-api-key-here
```

> **注意：** LiteLLM 充当代理，通过统一接口支持多个 LLM 提供商。如果使用此选项，您需要单独设置 LiteLLM。

#### 步骤 3：以 LLM 模式启动服务器

**重要：** 您必须使用 `--use-llm` 标志来启用 LLM 模式：

```bash
npm run dev --use-llm
```

**预期输出：**
```
[11:43:41.000] INFO: Starting AG-UI test server...
[11:43:41.123] INFO: Agent mode: llm          # ← 确认 LLM 模式已激活
[11:43:41.234] INFO: LLM provider: deepseek   # ← 显示您的提供商
[11:43:41.456] INFO: Server listening at http://0.0.0.0:3000
```

现在您的 iOS 应用将获得真实的 AI 响应！

**故障排除：**
- 如果您看到 `Agent mode: emulated` 而不是 `llm`，请确保包含了 `--use-llm` 标志
- 如果出现 API 错误，请验证 `.env` 中的 API 密钥是否正确
- 检查 `.env` 文件是否在 `demo-apps/server/agui-test-server/` 目录中

### 在物理设备上运行

1. **获取您的 Mac IP 地址：**
   - 前往：系统设置 → 网络 → Wi-Fi → 详细信息
   - 记下 IP 地址（例如，`192.168.1.100`）

2. **确保 Mac 和 iPhone 在同一 Wi-Fi 网络上**

3. **更新 iOS 应用服务器 URL：**

   **Simple（Swift）** - 编辑 `demo-apps/iOS/Simple/App/App/AppConfig.swift`：
   ```swift
   static let defaultServerURL = URL(string: "http://192.168.1.100:3000/agent")!
   ```

   **SimpleObjC** - 编辑 `demo-apps/iOS/SimpleObjC/App/Coordinators/ChatCoordinator.m`：
   ```objc
   NSURL *serverURL = [NSURL URLWithString:@"http://192.168.1.100:3000/agent"];
   ```

4. **重新构建并运行：**
   ```bash
   make clean
   make generate
   make run
   ```

### 查看服务器日志

服务器在开发模式下输出详细日志：

```bash
cd demo-apps/server/agui-test-server
npm run dev
```

**日志级别：**
- `INFO` - 正常操作
- `WARN` - 警告（可恢复的问题）
- `ERROR` - 错误（请求失败）

**有用的日志：**
- 传入请求：`POST /agent`
- 代理响应：消息块和工具调用
- 连接问题：客户端断开连接

---

## 下一步

- **自定义示例**：参见示例 README 文件了解架构详情
- **探索服务器选项**：[服务器文档](../demo-apps/server/README.md)
- **构建您自己的应用**：[ChatKit 开发者指南](guides/developer-guide.zh.md)
- **理解协议**：[AG-UI 规范](../demo-apps/server/agui-test-server/docs/agui-compliance.md)

---

## 快速参考

### 常用命令

```bash
# 后端服务器
cd demo-apps/server/agui-test-server
npm install           # 安装（首次）
npm run dev           # 启动服务器
npm test              # 运行测试
npm run build         # 为生产构建

# iOS Simple 示例
cd demo-apps/iOS/Simple
make generate         # 生成 Xcode 项目
make run              # 构建并运行
make clean            # 清理构建产物
make open             # 在 Xcode 中打开

# iOS SimpleObjC 示例
cd demo-apps/iOS/SimpleObjC
make generate         # 生成 Xcode 项目
make run              # 构建并运行
make clean            # 清理构建产物
```

### 默认配置

| 组件 | 默认值 |
|-----------|---------------|
| 服务器 URL | `http://127.0.0.1:3000` |
| 服务器端口 | `3000` |
| 代理类型 | `scenario`（预脚本） |
| 代理 ID | `E1E72B3D-845D-4F5D-B6CA-5550F2643E6B` |
| 用户 ID | `demo-user` |
| iOS 模拟器 | iPhone 17 |

---

**需要帮助？** 参见[故障排除指南](troubleshooting.zh.md)或[提交 issue](https://github.com/Geeksfino/finclip-chatkit/issues)。
