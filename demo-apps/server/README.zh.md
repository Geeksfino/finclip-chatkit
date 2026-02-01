# 演示后端服务器

用于测试 ChatKit 演示应用的后端服务器。这些服务器实现了 ChatKit 移动应用演示所需的协议，并提供各种代理类型用于测试不同场景。

## 📦 可用服务器

### agui-test-server
**AG-UI 协议测试服务器**，包含多种代理类型：
- 🎭 基于场景的（预编写脚本响应）
- 🔄 回声代理（简单测试）
- 🤖 LiteLLM 集成（通过代理的真实 LLM）
- 🧠 DeepSeek 集成（直接 API）

**最适合**：使用可预测响应或真实 AI 测试移动应用演示。

[→ agui-test-server 文档](agui-test-server/README.md)

### mcpui-test-server  
**MCP-UI / MCP Apps 协议测试服务器**，用于测试交互式 Web 组件和小部件。

> **📌 协议更新**: MCP-UI 现已标准化为 MCP Apps。本服务器同时支持 MCP Apps 标准和传统 MCP-UI 协议。更多信息请参考 [MCP-UI 官网](https://mcpui.dev/)。

**最适合**：测试高级 UI 组件，如表单、按钮和嵌入式小部件。

[→ mcpui-test-server 文档](mcpui-test-server/README.md)

### a2ui-test-server
**A2UI 协议测试服务器**，用于测试从 AI 代理生成声明式 UI。

**最适合**: 测试 A2UI 协议集成、基于场景的 UI 生成和 LLM 驱动的 UI 创建。

[→ a2ui-test-server 文档](a2ui-test-server/README.md)

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
cd demo-apps/server/mcpui-test-server
npm install
npm run dev
```

服务器运行在 **http://localhost:3100**。

### 运行 a2ui-test-server

```bash
cd demo-apps/server/a2ui-test-server
npm install
npm run dev
```

服务器运行在 **http://localhost:3200**。使用 agui-test-server 且 `EXTENSION_MODE=a2ui` 时需要启动。

---

## 🔧 配置

### agui-test-server 配置

编辑 `agui-test-server/.env`（完整选项见 `.env.example`）：

```env
# 服务器
PORT=3000
HOST=0.0.0.0

# 代理模式：emulated | llm
AGENT_MODE=emulated          # 预脚本（默认）或真实 LLM

# AGENT_MODE=emulated 时：场景 ID（echo | simple-chat | tool-call | error-handling）
DEFAULT_SCENARIO=tool-call

# AGENT_MODE=llm 时：LLM 提供商（deepseek | openai | siliconflow | litellm）
LLM_PROVIDER=deepseek
LLM_MODEL=deepseek-chat
LLM_API_KEY=your-api-key

# 扩展模式：none | mcpui | a2ui（启用 MCPUI 工具或 A2UI 代理）
EXTENSION_MODE=none
MCPUI_SERVER_URL=http://localhost:3100/mcp   # EXTENSION_MODE=mcpui 时
A2UI_SERVER_URL=http://localhost:3200        # EXTENSION_MODE=a2ui 时
```

### mcpui-test-server 配置

编辑 `mcpui-test-server/.env`：

```env
PORT=3100                    # MCP 服务（EXTENSION_MODE=mcpui 时 agui 连接此地址）
HOST=0.0.0.0
```

### a2ui-test-server 配置

编辑 `a2ui-test-server/.env`：

```env
PORT=3200
HOST=0.0.0.0
```

---

## 📱 与移动应用演示配合使用

### iOS Simple 演示（Swift）

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

### iOS SimpleObjC 演示（Objective-C）

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

### Scenario 代理（模拟 - 默认）

**适用于**：可预测响应进行测试。

设置 `AGENT_MODE=emulated` 和 `DEFAULT_SCENARIO=<id>`：
- `simple-chat` - 基本对话
- `tool-call` - 功能调用演示
- `error-handling` - 错误场景

### Echo 代理

设置 `AGENT_MODE=emulated` 和 `DEFAULT_SCENARIO=echo` 可回显用户输入。

### LLM 代理

**适用于**：真实 AI 响应。

1. 设置 `AGENT_MODE=llm`（或运行 `npm run dev -- --use-llm`）
2. 在 `.env` 中配置 `LLM_PROVIDER`、`LLM_MODEL`、`LLM_API_KEY`
3. 支持的提供商：`deepseek`、`openai`、`siliconflow`、`litellm`

完整配置见 [agui-test-server README](agui-test-server/README.md)。

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

### 移动应用无法连接 - "网络错误"

1. **检查服务器是否正在运行**：
   ```bash
   curl http://localhost:3000/health
   ```

2. **如果使用模拟器/模拟器**：
   - iOS 模拟器：`localhost` 和 `127.0.0.1` 工作正常
   - Android 模拟器：使用 `10.0.2.2` 代替 `localhost`

3. **如果使用物理设备**： 
   - 使用开发机器的本地 IP（例如，`http://192.168.1.100:3000`）
   - 查找 IP：`系统设置 → 网络 → Wi-Fi → 详细信息 → IP 地址`（macOS）或网络设置（其他系统）
   - 确保设备和开发机器在同一 Wi-Fi 网络上

### LLM 无响应

1. **检查 API 密钥**（来自 agui `.env`）：
   ```bash
   echo $LLM_API_KEY
   ```

2. **直接测试 API**（DeepSeek 示例）：
   ```bash
   curl https://api.deepseek.com/v1/chat/completions \
     -H "Authorization: Bearer $LLM_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"你好"}]}'
   ```

3. **查看服务器日志**获取具体错误信息

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

- [agui-test-server README](agui-test-server/README.md) - AG-UI 服务器文档
- [mcpui-test-server README](mcpui-test-server/README.md) - MCP-UI 服务器文档
- [a2ui-test-server README](a2ui-test-server/README.md) - A2UI 服务器文档
- [ChatKit 开发者指南](../../docs/guides/developer-guide.md) - 移动 SDK 集成指南
- [agui-test-server docs](agui-test-server/docs/) - architecture、agui-compliance、resilience

---

## 🤝 支持

遇到问题？请查看：
1. 上述故障排除部分
2. 服务器特定 README 以获取详细文档
3. [ChatKit 故障排除指南](../../docs/troubleshooting.md)
4. [GitHub Issues](https://github.com/Geeksfino/finclip-chatkit/issues)

---

**祝测试愉快！🚀**
