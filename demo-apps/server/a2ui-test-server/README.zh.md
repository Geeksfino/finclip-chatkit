# A2UI 测试服务器

用于 ChatKit SDK 集成测试的 A2UI 协议测试服务器。实现 A2UI (Agent to UI) Protocol v0.8，支持基于场景和 LLM 驱动的 UI 生成。

## 功能特性

- ✅ **完整的 A2UI 协议 v0.8** - 实现完整的 A2UI 规范
- 🎭 **多种 Agent 类型** - 场景模式（预定义）和 LLM 驱动
- 📡 **SSE JSONL 流式传输** - 服务器发送事件，JSON Lines 格式
- 🎨 **标准组件** - Text、Button、Row、Column、Card、TextField、DateTimeInput、List
- 📊 **数据绑定** - 完整支持数据模型更新和绑定
- 🔄 **渐进式渲染** - 增量流式传输 UI 组件
- 🚀 **高性能** - 基于 Fastify 构建，实现最大吞吐量
- 📝 **结构化日志** - 基于 Pino 的日志记录，具有美观的输出

## 快速开始

### 前置要求

- Node.js 20+
- npm/yarn/pnpm

### 安装

```bash
cd a2ui-test-server
npm install
# 或
pnpm install
```

### 配置

复制 `.env.example` 到 `.env`：

```bash
cp .env.example .env
```

配置选项：

```env
PORT=3200
HOST=0.0.0.0
NODE_ENV=development

# Agent 配置
DEFAULT_AGENT=scenario  # scenario 或 llm
SCENARIO_DIR=./src/scenarios
SCENARIO_DELAY_MS=200

# LLM 配置（LLM 模式）
LLM_PROVIDER=gemini  # gemini 或 deepseek
GEMINI_API_KEY=your-gemini-api-key
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat

# SSE 配置
SSE_RETRY_MS=3000
SSE_HEARTBEAT_MS=30000

# 日志
LOG_LEVEL=info
LOG_PRETTY=true

# CORS
CORS_ORIGIN=*
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

服务器将在 `http://localhost:3200` 启动。

## API 端点

### POST /agent

主要 A2UI agent 端点。接受 **A2A Message 格式**（符合 [A2UI v0.8](https://a2ui.org/specification/v0.8-a2ui/)）并返回包含 A2UI JSONL 消息的 SSE 流。

**请求**（A2A Message）：
```json
{
  "metadata": {
    "a2uiClientCapabilities": {
      "supportedCatalogIds": [
        "https://github.com/google/A2UI/blob/main/specification/v0_8/json/standard_catalog_definition.json"
      ]
    },
    "surfaceId": "main",
    "threadId": "可选-会话id",
    "runId": "可选-runid"
  },
  "message": {
    "prompt": {
      "text": "你好，给我显示一个表单"
    }
  }
}
```

- `message.prompt.text`（必填）：用户输入文本
- `metadata.a2uiClientCapabilities`（可选）：Catalog 协商
- `metadata.surfaceId`（可选）：目标 surface，默认 `"main"`
- `metadata.threadId`、`metadata.runId`（可选）：AG-UI 编排用

**响应**：`text/event-stream` (JSONL 格式)

```
retry: 3000

data: {"surfaceUpdate":{"surfaceId":"main","components":[{"id":"root","component":{"Column":{"children":{"explicitList":["header"]}}}}]}}

data: {"surfaceUpdate":{"surfaceId":"main","components":[{"id":"header","component":{"Text":{"text":{"literalString":"你好"}}}}]}}

data: {"dataModelUpdate":{"surfaceId":"main","contents":[]}}

data: {"beginRendering":{"surfaceId":"main","root":"root"}}
```

### POST /action

处理来自 A2UI widget 的用户交互。

**请求**：
```json
{
  "userAction": {
    "name": "submit_form",
    "surfaceId": "main",
    "sourceComponentId": "submit-btn",
    "timestamp": "2025-01-27T10:00:00Z",
    "context": {
      "name": "张三",
      "email": "zhangsan@example.com"
    }
  }
}
```

**响应**：
- 如果需要 UI 更新：SSE 流，包含新的 A2UI 消息
- 否则：`{"status":"ok","message":"Action received"}`

### GET /health

健康检查端点。

**响应**：
```json
{
  "status": "ok",
  "timestamp": "2025-01-27T10:00:00.000Z",
  "uptime": 123.45,
  "sessions": 5,
  "version": "1.0.0"
}
```

## Agent 类型

### 场景 Agent（默认）

预定义的 A2UI 响应，用于确定性测试。

**可用场景**：
- `simple-ui` - 包含 Text 和 Button 的基本 UI
- `form-ui` - 包含多种输入类型的复杂表单
- `interactive-ui` - 包含数据绑定和动态更新的 UI

**用法**：
```bash
# 默认场景模式
DEFAULT_AGENT=scenario npm run dev
```

### LLM Agent

使用 LLM（Gemini 或 DeepSeek）生成 A2UI 消息。

**设置 Gemini**：
1. 从 [Google AI Studio](https://aistudio.google.com/apikey) 获取 API 密钥
2. 配置：
```env
DEFAULT_AGENT=llm
LLM_PROVIDER=gemini
GEMINI_API_KEY=your-gemini-api-key
```

**设置 DeepSeek**：
1. 从 [DeepSeek Platform](https://platform.deepseek.com/) 获取 API 密钥
2. 配置：
```env
DEFAULT_AGENT=llm
LLM_PROVIDER=deepseek
DEEPSEEK_API_KEY=your-deepseek-key
DEEPSEEK_MODEL=deepseek-chat
```

## A2UI 协议概述

### 消息格式

所有消息使用 JSON Lines (JSONL) 格式 - 每行一个 JSON 对象：

```json
{"surfaceUpdate":{"surfaceId":"main","components":[...]}}
{"dataModelUpdate":{"surfaceId":"main","contents":[...]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
```

### 消息类型

1. **surfaceUpdate** - 定义或更新 UI 组件
2. **dataModelUpdate** - 更新数据模型以进行数据绑定
3. **beginRendering** - 通知客户端渲染（必须在组件定义之后）
4. **deleteSurface** - 从 UI 中移除 surface

### 组件模型

A2UI 使用**扁平邻接表模型**，组件通过 ID 引用子组件：

```json
{
  "surfaceUpdate": {
    "surfaceId": "main",
    "components": [
      {
        "id": "root",
        "component": {
          "Column": {
            "children": {
              "explicitList": ["text1", "button1"]
            }
          }
        }
      },
      {
        "id": "text1",
        "component": {
          "Text": {
            "text": {
              "literalString": "你好"
            }
          }
        }
      }
    ]
  }
}
```

### 数据绑定

组件可以使用 `path` 绑定到数据模型：

```json
{
  "component": {
    "Text": {
      "text": {
        "path": "/user/name"
      }
    }
  }
}
```

数据模型单独更新：

```json
{
  "dataModelUpdate": {
    "surfaceId": "main",
    "path": "user",
    "contents": [
      {
        "key": "name",
        "valueString": "张三"
      }
    ]
  }
}
```

## 测试

### cURL 示例

**发送 agent 请求**：
```bash
curl -X POST http://localhost:3200/agent \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "threadId": "test-123",
    "runId": "run_1",
    "message": "hello"
  }'
```

**发送用户操作**：
```bash
curl -X POST http://localhost:3200/action \
  -H "Content-Type: application/json" \
  -d '{
    "userAction": {
      "name": "increment",
      "surfaceId": "main",
      "sourceComponentId": "increment-btn",
      "timestamp": "2025-01-27T10:00:00Z",
      "context": {
        "currentValue": 5
      }
    }
  }'
```

### 单元测试

```bash
npm test
```

## 开发

### 项目结构

```
a2ui-test-server/
├── src/
│   ├── server.ts              # Fastify 服务器设置
│   ├── routes/
│   │   ├── agent.ts           # A2UI agent 端点
│   │   ├── action.ts          # 用户操作处理器
│   │   └── health.ts          # 健康检查
│   ├── agents/
│   │   ├── base.ts            # Agent 基类
│   │   ├── scenario.ts        # 基于场景的 agent
│   │   └── llm.ts             # LLM 驱动的 agent
│   ├── scenarios/
│   │   ├── index.ts           # 场景加载器
│   │   ├── simple-ui.json     # 简单 UI 场景
│   │   ├── form-ui.json       # 表单 UI 场景
│   │   └── interactive-ui.json # 交互式 UI 场景
│   ├── streaming/
│   │   ├── jsonl-encoder.ts   # SSE 的 JSONL 编码器
│   │   └── session.ts         # 会话管理
│   ├── types/
│   │   ├── a2ui.ts            # A2UI 消息类型
│   │   └── scenario.ts        # 场景类型
│   └── utils/
│       ├── config.ts          # 配置加载器
│       ├── logger.ts          # 日志设置
│       └── validation.ts      # 输入验证
├── tests/
├── .env.example
├── package.json
└── README.zh.md
```

## 参考资料

- [A2UI 协议规范](https://a2ui.org/specification/v0.8-a2ui/)
- [A2UI 消息参考](https://a2ui.org/reference/messages/)
- [A2UI GitHub 仓库](https://github.com/google/A2UI)

## 许可证

MIT 许可证 - 详见 [LICENSE](../../../LICENSE)

---

**由 FinClip 团队用 ❤️ 制作**
