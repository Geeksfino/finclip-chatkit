# 演示后端服务器

用于测试 ChatKit 演示应用的后端服务器。这些服务器实现了 ChatKit iOS 演示所需的协议，并提供各种代理类型用于测试不同场景。

## 📦 可用服务器

### agui-test-server
**AG-UI 协议测试服务器**，包含多种代理类型：
- 🎭 基于场景的（预编写脚本响应）
- 🔄 回声代理（简单测试）
- 🤖 LiteLLM 集成（通过代理的真实 LLM）
- 🧠 DeepSeek 集成（直接 API）

**最适合**：使用可预测响应或真实 AI 测试 iOS 演示。

[→ agui-test-server 文档](agui-test-server/README.md)

### mcpui-test-server  
**MCP-UI 协议测试服务器**，用于测试交互式 Web 组件和小部件。

**最适合**：测试高级 UI 组件，如表单、按钮和嵌入式小部件。

[→ mcpui-test-server 文档](mcpui-test-server/README.md)

---

## 🚀 快速开始

### 前置要求

- **Node.js 20+**（[下载](https://nodejs.org/)）
- **npm**（包含在 Node.js 中）或 **pnpm**（推荐）

安装 pnpm（可选但更快）：
```bash
npm install -g pnpm
```

### 运行 agui-test-server（推荐入门使用）

这是您在 iOS 演示中最常使用的服务器：

```bash
# 导航到服务器目录
cd demo-apps/server/agui-test-server

# 安装依赖项
npm install
# 或
pnpm install

# 配置环境（可选）
cp .env.example .env
# 如需要，编辑 .env（默认值工作正常）

# 以开发模式启动服务器
npm run dev
```

服务器将在 **http://localhost:3000** 启动

您应该看到：
```
✓ Server listening at http://0.0.0.0:3000
✓ Default agent type: scenario
```

### 运行 mcpui-test-server

```bash
# 导航到服务器目录
cd demo-apps/server/mcpui-test-server

# 安装依赖项
npm install
# 或
pnpm install

# 启动服务器
npm run dev
```

---

## 🔧 配置

### agui-test-server 配置

编辑 `agui-test-server/.env`：

```env
# 服务器设置
PORT=3000                    # 监听端口
HOST=0.0.0.0                 # 绑定主机

# 代理类型（选择一个）
DEFAULT_AGENT=scenario       # 预编写脚本响应（推荐用于测试）
# DEFAULT_AGENT=echo         # 简单回声代理
# DEFAULT_AGENT=litellm      # LiteLLM 代理集成
# DEFAULT_AGENT=deepseek     # 直接 DeepSeek API

# LiteLLM 设置（如果使用 DEFAULT_AGENT=litellm）
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_API_KEY=your-key
LITELLM_MODEL=deepseek-chat

# DeepSeek 设置（如果使用 DEFAULT_AGENT=deepseek）
DEEPSEEK_API_KEY=your-deepseek-api-key
DEEPSEEK_MODEL=deepseek-chat
DEEPSEEK_BASE_URL=https://api.deepseek.com
```

### mcpui-test-server 配置

编辑 `mcpui-test-server/.env`：

```env
PORT=3001                    # 使用不同端口避免冲突
HOST=0.0.0.0
```

---

## 📱 与 iOS 演示配合使用

### Simple 演示（Swift）

1. **启动服务器**：
   ```bash
   cd demo-apps/server/agui-test-server
   npm run dev
   ```

2. **运行 iOS 应用**：
   ```bash
   cd demo-apps/iOS/Simple
   make run
   ```

3. **在应用中**：
   - 默认服务器 URL 已设置为 `http://127.0.0.1:3000/agent`
   - 点击 "Connect" → 点击 "+" 创建对话
   - 开始聊天！

### SimpleObjC 演示（Objective-C）

与上述步骤相同，但运行：
```bash
cd demo-apps/iOS/SimpleObjC
make run
```

---

## 🧪 测试服务器

### 快速健康检查

```bash
curl http://localhost:3000/health
```

预期响应：
```json
{
  "status": "ok",
  "timestamp": "2025-11-12T09:43:41.000Z",
  "uptime": 123.45,
  "sessions": 0
}
```

### 测试简单聊天

```bash
curl -X POST http://localhost:3000/agent \
  -H "Content-Type: application/json" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1731405821_abc",
    "messages": [
      {
        "id": "msg-1",
        "role": "user",
        "content": "你好"
      }
    ],
    "tools": [],
    "context": [],
    "state": null
  }'
```

您将看到服务器发送事件（SSE）流：
```
event: message
data: {"type":"RUN_STARTED","threadId":"test-123","runId":"run_1731405821_abc"}

event: message
data: {"type":"TEXT_MESSAGE_CHUNK","messageId":"msg-xxx","delta":"你好"}

event: message
data: {"type":"RUN_FINISHED","threadId":"test-123","runId":"run_1731405821_abc"}
```

### 列出可用场景

```bash
curl http://localhost:3000/scenarios
```

---

## 🔄 代理类型说明

### Scenario 代理（默认 - 推荐）

**适用于**：您想要可预测、确定性的响应进行测试。

基于对话模式的预编写脚本响应。非常适合：
- 单元测试
- 演示录制
- 可重现的行为

**可用场景**：
- `simple-chat` - 基本对话
- `tool-call` - 功能调用演示
- `error-handling` - 错误场景

### Echo 代理

**适用于**：您只想测试连接和消息流。

简单地回显用户发送的内容。适合：
- 测试网络
- 调试消息格式
- 健全性检查

启用方式：
```env
DEFAULT_AGENT=echo
```

### LiteLLM 代理

**适用于**：您想要来自任何 LLM 提供商的真实 AI 响应。

连接到可以路由到 OpenAI、Anthropic、DeepSeek 等的 LiteLLM 代理。

**设置**：
1. 安装 LiteLLM：
   ```bash
   pip install litellm
   ```

2. 启动 LiteLLM 代理：
   ```bash
   litellm --model deepseek/deepseek-chat --api_key $DEEPSEEK_API_KEY
   ```

3. 配置服务器：
   ```env
   DEFAULT_AGENT=litellm
   LITELLM_ENDPOINT=http://localhost:4000/v1
   ```

### DeepSeek 代理

**适用于**：您想要直接 DeepSeek API 集成，无需 LiteLLM。

使用 DeepSeek 获得真实 AI 响应的最快途径。

**设置**：
1. 从 [DeepSeek](https://platform.deepseek.com/) 获取 API 密钥

2. 配置服务器：
   ```env
   DEFAULT_AGENT=deepseek
   DEEPSEEK_API_KEY=your-key-here
   ```

---

## 🛠️ 开发

### 热重载

两个服务器都在开发模式下支持热重载：

```bash
npm run dev
```

代码更改会自动重启服务器。

### 生产环境构建

```bash
# 构建
npm run build

# 运行生产构建
npm start
```

### 运行测试

```bash
# 运行所有测试
npm test

# 运行并显示覆盖率
npm run test:coverage
```

---

## 🐛 故障排除

### 服务器无法启动 - "端口已被使用"

另一个进程正在使用端口 3000：

```bash
# 查找使用该端口的进程
lsof -i :3000

# 终止进程（将 PID 替换为实际进程 ID）
kill -9 PID
```

或在 `.env` 中更改端口：
```env
PORT=3001
```

### iOS 应用无法连接 - "网络错误"

1. **检查服务器是否正在运行**：
   ```bash
   curl http://localhost:3000/health
   ```

2. **如果使用 iOS 模拟器**：`localhost` 和 `127.0.0.1` 工作正常

3. **如果使用物理设备**： 
   - 使用 Mac 的本地 IP（例如，`http://192.168.1.100:3000`）
   - 查找 IP：`系统设置 → 网络 → Wi-Fi → 详细信息 → IP 地址`
   - 确保设备和 Mac 在同一 Wi-Fi 网络上

### LiteLLM/DeepSeek 无响应

1. **检查是否设置了 API 密钥**：
   ```bash
   echo $DEEPSEEK_API_KEY
   ```

2. **直接测试 API**：
   ```bash
   curl https://api.deepseek.com/v1/chat/completions \
     -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"你好"}]}'
   ```

3. **检查服务器日志**以获取特定错误消息

### 依赖项无法安装

1. **清除缓存并重新安装**：
   ```bash
   rm -rf node_modules package-lock.json
   npm install
   ```

2. **尝试 pnpm**（通常更可靠）：
   ```bash
   npm install -g pnpm
   pnpm install
   ```

---

## 📚 延伸阅读

- [agui-test-server README](agui-test-server/README.md) - 完整的 AG-UI 服务器文档
- [mcpui-test-server README](mcpui-test-server/README.md) - 完整的 MCP-UI 服务器文档
- [ChatKit 开发者指南](../../docs/guides/developer-guide.md) - iOS SDK 集成指南
- [AG-UI 协议规范](agui-test-server/docs/agui-compliance.md) - 协议规范

---

## 🤝 支持

遇到问题？请查看：
1. 上述故障排除部分
2. 服务器特定 README 以获取详细文档
3. [ChatKit 故障排除指南](../../docs/troubleshooting.md)
4. [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**祝测试愉快！🚀**
