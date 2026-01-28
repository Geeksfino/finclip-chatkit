# MCP-UI / MCP Apps 测试服务器

> **📌 协议更新说明**: MCP-UI 现已标准化为 **MCP Apps**，成为 MCP 中交互式 UI 的官方标准。本服务器同时支持 MCP Apps 标准和传统的 MCP-UI 协议，确保向后兼容性。更多信息请参考 [MCP-UI 官网](https://mcpui.dev/)。

用于 ChatKit 移动应用集成测试的综合 MCP-UI / MCP Apps 协议测试服务器。实现了具有完整 MCP-UI 支持的模型上下文协议（MCP）。

## 功能特性

- ✅ **完整的 MCP 协议** - 实现完整的 MCP 规范
- 🎨 **11 个 UI 资源工具** - 涵盖所有 MCP-UI 场景
- 📡 **HTTP 流式传输** - StreamableHTTPServerTransport
- 🔧 **3 种内容类型** - HTML、外部 URL、远程 DOM
- 📊 **元数据支持** - 首选大小、渲染数据
- 🔄 **异步协议** - 消息 ID、确认、响应
- 🚀 **高性能** - 基于 Fastify 构建
- 📝 **结构化日志** - 基于 Pino 的日志记录（Fastify 原生支持）

## 快速开始

### 前置要求

- Node.js 20+
- npm/yarn/pnpm

### 安装

```bash
cd mcpui-test-server
npm install
```

### 配置

复制 `.env.example` 到 `.env`：

```bash
cp .env.example .env
```

配置选项：

```env
PORT=3100
HOST=0.0.0.0
NODE_ENV=development
SERVER_NAME=mcpui-test-server
SERVER_VERSION=1.0.0
LOG_LEVEL=info
LOG_PRETTY=true
CORS_ORIGIN=*
SESSION_TIMEOUT=3600000
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

服务器将在 `http://localhost:3100` 启动。

## API 端点

### MCP 协议端点

- `POST /mcp` - 客户端到服务器通信
- `GET /mcp` - 服务器到客户端流
- `DELETE /mcp` - 会话终止

### 实用端点

- `GET /health` - 健康检查
- `GET /tools` - 列出所有可用工具

## 可用工具

### HTML 内容工具（3 个）

1. **showSimpleHtml** - 带样式和交互按钮的基本 HTML
2. **showInteractiveForm** - 带验证和异步提交的表单
3. **showComplexLayout** - 多列响应式布局

### 外部 URL 工具（3 个）

4. **showExampleSite** - 显示 example.com
5. **showCustomUrl** - 显示用户提供的 URL
6. **showApiDocs** - 显示 MCP-UI 文档

### 远程 DOM 工具（2 个）

7. **showRemoteDomButton** - 带计数器的交互按钮
8. **showRemoteDomForm** - 带验证的表单

### 元数据工具（2 个）

9. **showWithPreferredSize** - 演示 preferred-frame-size
10. **showWithRenderData** - 演示 initial-render-data

### 异步协议工具（1 个）

11. **showAsyncToolCall** - 演示异步消息协议

## 使用 ConvoUI-iOS 测试

### Swift 集成

```swift
import ConvoUI

let mcpClient = MCPClient(serverURL: URL(string: "http://localhost:3100")!)

// 初始化连接
try await mcpClient.initialize()

// 列出工具
let tools = try await mcpClient.listTools()

// 调用工具
let result = try await mcpClient.callTool(name: "showSimpleHtml", parameters: [:])

// 显示 UI 资源
if let resource = result.content.first {
    let message = FinConvoMCPUIMessageModel.messageFromMCPResource(
        resource,
        messageId: UUID().uuidString,
        timestamp: Date()
    )
    resourceView.loadResource(message)
}
```

### cURL 测试

```bash
# 初始化会话
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2024-11-05",
      "capabilities": {},
      "clientInfo": {"name": "test", "version": "1.0.0"}
    }
  }'

# 列出工具
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/list"
  }'

# 调用工具
curl -X POST http://localhost:3100/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "showSimpleHtml",
      "arguments": {}
    }
  }'
```

## MCP 协议概述

### 消息格式

所有消息使用 JSON-RPC 2.0 格式：

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "method_name",
  "params": {...}
}
```

### 初始化流程

1. 客户端发送 `initialize` 请求
2. 服务器以功能和工具列表响应
3. 客户端发送 `initialized` 通知
4. 连接就绪

### 工具调用流程

1. 客户端发送 `tools/call` 请求
2. 服务器返回带 UI 资源的 `CallToolResult`
3. 客户端在 WebView 中渲染资源

### 远程 DOM 交互

1. 服务器发送带 `remoteDOM` 的 UI 资源
2. 客户端在 WebView 中加载
3. 用户交互触发消息
4. 客户端将消息发送回服务器
5. 服务器更新 DOM 并响应

## 开发

### 项目结构

```
mcpui-test-server/
├── src/
│   ├── server.ts              # Fastify 服务器入口
│   ├── routes/
│   │   ├── health.ts          # 健康检查端点
│   │   ├── tools.ts           # 工具列表端点
│   │   └── mcp.ts             # MCP 协议端点
│   ├── mcp/
│   │   └── session.ts         # 会话管理
│   ├── tools/
│   │   ├── index.ts           # 工具注册入口
│   │   ├── html.ts            # HTML 内容工具
│   │   ├── url.ts             # 外部 URL 工具
│   │   ├── remote-dom.ts      # 远程 DOM 工具
│   │   ├── metadata.ts        # 元数据工具
│   │   └── async.ts           # 异步协议工具
│   ├── types/
│   │   └── index.ts           # TypeScript 类型定义
│   └── utils/
│       ├── config.ts          # 配置加载器
│       └── logger.ts          # Pino 日志记录器
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

## 工具示例

### HTML 内容示例

```javascript
// 简单 HTML
{
  "type": "uiResource",
  "mimeType": "text/html",
  "htmlContent": "<div><h1>Hello World</h1></div>"
}

// 带样式的 HTML
{
  "type": "uiResource",
  "mimeType": "text/html",
  "htmlContent": "<style>h1{color:blue}</style><h1>Styled</h1>"
}
```

### 外部 URL 示例

```javascript
{
  "type": "uiResource",
  "mimeType": "text/html",
  "externalUrl": "https://example.com"
}
```

### 远程 DOM 示例

```javascript
{
  "type": "uiResource",
  "mimeType": "text/html",
  "remoteDOM": {
    "html": "<button id='btn'>点击我</button>",
    "handlers": [
      {
        "selector": "#btn",
        "event": "click",
        "action": "increment_counter"
      }
    ]
  }
}
```

### 元数据示例

```javascript
{
  "type": "uiResource",
  "mimeType": "text/html",
  "htmlContent": "<div>内容</div>",
  "metadata": {
    "preferredFrameSize": {
      "width": 400,
      "height": 300
    },
    "initialRenderData": {
      "count": 0
    }
  }
}
```

## 部署

### Docker

```bash
# 构建镜像
docker build -t mcpui-test-server .

# 运行容器
docker run -p 3100:3100 mcpui-test-server
```

### Docker Compose

```yaml
version: '3.8'
services:
  mcpui-test-server:
    build: .
    ports:
      - "3100:3100"
    environment:
      - PORT=3100
      - NODE_ENV=production
    restart: unless-stopped
```

## 故障排除

### 常见问题

**端口已被使用**
```bash
# 查找进程
lsof -i :3100
# 更改端口
PORT=3101 npm run dev
```

**CORS 错误**
```bash
# 设置允许的来源
CORS_ORIGIN=http://localhost:8080 npm run dev
```

**会话超时**
```bash
# 增加超时
SESSION_TIMEOUT=7200000 npm run dev  # 2 小时
```

## 性能

### 基准测试

```bash
# 安装 autocannon
npm install -g autocannon

# 运行基准测试
autocannon -c 100 -d 30 http://localhost:3100/health
```

典型结果：
- 请求/秒：~15,000
- 延迟（p99）：<15ms
- 吞吐量：~10 MB/秒

## 协议规范

符合 MCP 规范版本 2024-11-05。

关键功能：
- ✅ 工具列表和调用
- ✅ UI 资源支持
- ✅ 远程 DOM 交互
- ✅ 异步消息协议
- ✅ 会话管理
- ✅ 错误处理

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
