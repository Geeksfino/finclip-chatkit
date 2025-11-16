# AG-UI 测试服务器

用于 NeuronKit SDK 集成测试的生产级 AG-UI 协议测试服务器。支持多种代理类型，包括预编写脚本场景、回声测试以及通过 LiteLLM 或 DeepSeek 的真实 LLM 集成。

## 功能特性

- ✅ **完整的 AG-UI 协议支持** - 实现完整的 AG-UI 规范
- 🎭 **多种代理类型** - Scenario、Echo、LiteLLM、DeepSeek
- 📡 **SSE 流式传输** - 具有正确事件编码的服务器发送事件
- 🧪 **测试场景** - 用于确定性测试的预构建场景
- 🔌 **LiteLLM 集成** - 与提供商无关的 LLM 访问
- 🚀 **高性能** - 基于 Fastify 构建，实现最大吞吐量
- 📊 **会话管理** - 跨多轮对话跟踪会话
- 🔍 **结构化日志** - 基于 Pino 的日志记录，具有美观的输出

## 快速开始

### 前置要求

- Node.js 20+
- npm/yarn/pnpm

### 安装

```bash
cd agui-test-server
npm install
```

### 配置

复制 `.env.example` 到 `.env` 并配置：

```bash
cp .env.example .env
```

关键配置选项：

```env
# 服务器
PORT=3000
HOST=0.0.0.0

# 默认代理类型
DEFAULT_AGENT=scenario

# LLM 集成（可选）
LLM_PROVIDER=litellm
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_API_KEY=your-key
LITELLM_MODEL=deepseek-chat
```

### 运行服务器

**开发模式**（带热重载）：
```bash
npm run dev
```

**生产模式**：
```bash
npm run build
npm start
```

服务器将在 `http://localhost:3000` 启动。

## API 端点

### POST /agent

主要 AG-UI 端点。接受 `RunAgentInput` 并返回 SSE 流。

**请求**：
```json
{
  "threadId": "uuid",
  "runId": "run_timestamp_random",
  "messages": [
    {
      "id": "msg-uuid",
      "role": "user",
      "content": "你好"
    }
  ],
  "tools": [],
  "context": [],
  "state": null,
  "forwardedProps": null
}
```

**响应**：`text/event-stream`

```
event: message
data: {"type":"RUN_STARTED","threadId":"...","runId":"..."}

event: message
data: {"type":"TEXT_MESSAGE_CHUNK","messageId":"...","delta":"你好"}

event: message
data: {"type":"RUN_FINISHED","threadId":"...","runId":"..."}
```

### GET /scenarios

列出所有可用的测试场景。

**响应**：
```json
{
  "scenarios": [
    {
      "id": "simple-chat",
      "name": "Simple Chat",
      "description": "Basic conversation with greeting",
      "turnCount": 2
    }
  ]
}
```

### POST /scenarios/:id

直接运行特定场景（用于测试）。

**请求**：
```json
{
  "threadId": "test-123",
  "messages": [
    {
      "id": "msg-1",
      "role": "user",
      "content": "你好"
    }
  ]
}
```

### GET /health

健康检查端点。

**响应**：
```json
{
  "status": "ok",
  "timestamp": "2025-10-01T06:00:00.000Z",
  "uptime": 123.45,
  "sessions": 5
}
```

## 代理类型

### Scenario 代理（默认）

用于确定性测试的预编写脚本响应。

**可用场景**：
- `simple-chat` - 基本对话
- `tool-call` - 工具调用演示
- `error-handling` - 错误场景

**使用**：
```bash
curl -X POST http://localhost:3000/scenarios/simple-chat \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"id":"1","role":"user","content":"你好"}]}'
```

### Echo 代理

用于基本连接测试的简单回声代理。

**配置**：
```env
DEFAULT_AGENT=echo
```

### LiteLLM 代理

通过 LiteLLM 代理连接到任何 LLM。

**设置 LiteLLM**：
```bash
# 安装 LiteLLM
pip install litellm

# 启动代理
litellm --model deepseek/deepseek-chat --api_key $DEEPSEEK_API_KEY
```

**配置**：
```env
DEFAULT_AGENT=litellm
LITELLM_ENDPOINT=http://localhost:4000/v1
LITELLM_API_KEY=your-key
LITELLM_MODEL=deepseek-chat
```

### DeepSeek 代理

直接 DeepSeek API 集成。

**配置**：
```env
DEFAULT_AGENT=deepseek
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat
```

## 使用 NeuronKit 测试

### Swift 集成

```swift
import NeuronKit

let config = NeuronKitConfig(
    serverURL: URL(string: "http://localhost:3000/agent")!,
    deviceId: "test-device",
    userId: "test-user",
    storage: .inMemory
)

let runtime = NeuronRuntime(config: config)
let conversation = runtime.openConversation(agentId: UUID())

// 发送消息
try await conversation.sendMessage("你好！")

// 绑定 UI
conversation.bindUI(myUIAdapter)
```

### cURL 测试

```bash
# 简单聊天
curl -X POST http://localhost:3000/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1",
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

## 开发

### 项目结构

```
agui-test-server/
├── src/
│   ├── server.ts              # Fastify 服务器设置
│   ├── routes/                # API 路由
│   │   ├── agent.ts           # /agent 端点
│   │   ├── scenarios.ts       # /scenarios 端点
│   │   └── health.ts          # /health 端点
│   ├── agents/                # 代理实现
│   │   ├── scenario.ts        # Scenario 代理
│   │   ├── echo.ts            # Echo 代理
│   │   ├── litellm.ts         # LiteLLM 代理
│   │   └── deepseek.ts        # DeepSeek 代理
│   ├── scenarios/             # 测试场景
│   │   └── definitions.ts     # 场景定义
│   └── utils/                 # 实用工具
│       ├── logger.ts          # Pino 日志记录器
│       └── sse.ts             # SSE 助手
├── tests/                     # 单元测试
├── .env.example               # 环境变量模板
└── package.json
```

### 运行测试

```bash
# 运行所有测试
npm test

# 带覆盖率运行
npm run test:coverage

# 监视模式
npm run test:watch
```

### 代码质量

```bash
# 检查代码
npm run lint

# 修复代码
npm run lint:fix

# 类型检查
npm run type-check
```

## 部署

### Docker

```bash
# 构建镜像
docker build -t agui-test-server .

# 运行容器
docker run -p 3000:3000 \
  -e DEFAULT_AGENT=scenario \
  agui-test-server
```

### Docker Compose

```yaml
version: '3.8'
services:
  agui-test-server:
    build: .
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - DEFAULT_AGENT=scenario
    restart: unless-stopped
```

## 协议规范

此服务器实现 AG-UI 协议规范。关键概念：

### 消息类型

- `RUN_STARTED` - 运行开始
- `TEXT_MESSAGE_CHUNK` - 文本消息块（流式）
- `TEXT_MESSAGE_FINISHED` - 文本消息完成
- `TOOL_CALL` - 工具调用请求
- `TOOL_RESULT` - 工具调用结果
- `RUN_FINISHED` - 运行完成
- `RUN_ERROR` - 运行错误

### 流式传输

服务器使用服务器发送事件（SSE）进行实时流式传输：
- 内容类型：`text/event-stream`
- 事件格式：`event: message\ndata: <JSON>\n\n`
- 自动重新连接支持

## 故障排除

### 常见问题

**端口已被使用**
```bash
# 查找进程
lsof -i :3000
# 更改端口
PORT=3001 npm run dev
```

**LiteLLM 连接失败**
```bash
# 验证 LiteLLM 正在运行
curl http://localhost:4000/health
# 检查配置
echo $LITELLM_ENDPOINT
```

**DeepSeek API 错误**
```bash
# 测试 API 密钥
curl https://api.deepseek.com/v1/chat/completions \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"deepseek-chat","messages":[{"role":"user","content":"测试"}]}'
```

## 性能

### 基准测试

```bash
# 安装 autocannon
npm install -g autocannon

# 运行基准测试
autocannon -c 100 -d 30 http://localhost:3000/health
```

典型结果：
- 请求/秒：~20,000
- 延迟（p99）：<10ms
- 吞吐量：~15 MB/秒

### 优化

- ✅ 使用 Fastify 实现高性能
- ✅ 异步/等待所有 I/O
- ✅ 连接池用于 LLM
- ✅ 响应流式传输
- ✅ 高效的 JSON 序列化

## 贡献

欢迎贡献！请：
1. Fork 仓库
2. 创建功能分支
3. 提交带测试的更改
4. 打开拉取请求

## 许可证

MIT 许可证 - 详见 [LICENSE](../../../LICENSE)

---

**由 FinClip 团队用 ❤️ 制作**
