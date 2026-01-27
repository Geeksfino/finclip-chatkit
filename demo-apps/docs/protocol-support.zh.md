# 协议和约定支持

ChatKit 为现代 AI 代理协议和 UI 约定提供全面支持,实现与更广泛的 AI 生态系统的无缝集成。

## 🤖 AG-UI 协议支持

ChatKit 通过 NeuronKit 包含完整的 **AG-UI(代理 UI)协议**支持,使您能够构建与 AG-UI 服务器兼容的智能副驾驶应用(相当于 Web 的 CopilotKit)。

**主要功能:**
- ✅ **完整的 SSE 事件支持** - 所有 AG-UI 事件类型(`RUN_*`、`TEXT_MESSAGE_*`、`TOOL_CALL_*` 等)
- ✅ **类型化工具参数** - 保留 JSON 类型(数字、布尔值、对象、数组)而不是转换为字符串
- ✅ **多会话 SSE** - 具有独立 SSE 连接的多个并发对话会话
- ✅ **文本流** - 带序列跟踪的实时增量文本流
- ✅ **工具/函数调用** - 代理通过 Sandbox PDP 请求工具执行并进行适当的同意流程
- ✅ **线程管理** - 使用 `runId` 和元数据跟踪对话线程
- ✅ **双向通信** - HTTP POST 用于出站消息,SSE 用于入站流

**用法:**
```swift
import FinClipChatKit

let config = NeuronKitConfig.default(serverURL: URL(string: "https://your-agui-server.com/agent")!)
    .withUserId("user-123")

let coordinator = ChatKitCoordinator(config: config)

// 配置 AG-UI 适配器
let aguiAdapter = AGUI_Adapter(
    baseEventURL: URL(string: "https://your-agui-server.com/agent")!,
    connectionMode: .postStream  // POST 与 SSE 响应
)
coordinator.runtime.setNetworkAdapter(aguiAdapter)

// 启动对话 - 自动使用 AG-UI 协议
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)
```

**连接模式:**
- **POST Stream**(推荐):用于发送消息和接收 SSE 响应的单一端点
- **Event Stream**:SSE 连接和消息发送的独立端点

## 🎨 OpenAI Apps SDK 桥接

ChatKit 包含一个 **OpenAI Bridge**,提供与 **OpenAI Apps SDK 小部件**的兼容性,使您能够使用为 OpenAI 的 chatkit-js 设计的小部件而无需修改。

**主要功能:**
- ✅ **`window.openai` API** - 完整的 JavaScript API 兼容性
- ✅ **基于 Promise 的架构** - 对工具调用和状态操作的 async/await 支持
- ✅ **状态管理** - 内置 `setState()` 和 `getState()` 用于小部件状态持久化
- ✅ **事件系统** - 支持 `on()` 和 `off()` 事件处理程序
- ✅ **原生集成** - 使用原生 WebView 和消息处理器进行安全的桥接通信

**用法:**
来自基于 OpenAI Apps SDK 的 MCP 服务器的小部件会自动在 ChatKit 的对话 UI 中渲染。桥接透明地处理所有 JavaScript 到原生的通信。

**JavaScript API(在小部件中):**
```javascript
// 基于 Promise 的工具调用
window.openai.callTool({
    name: "get_weather",
    parameters: { location: "San Francisco" }
}).then(result => {
    console.log("Weather:", result);
});

// 状态管理
window.openai.setState({ count: 5 });
const state = window.openai.getState(); // { count: 5 }
```

## 🌐 MCP-UI / MCP Apps 支持

> **📌 协议更新说明**: MCP-UI 现已标准化为 **MCP Apps**，成为 MCP 中交互式 UI 的官方标准。ChatKit 同时支持 MCP Apps 标准和传统的 MCP-UI 协议，确保向后兼容性。更多信息请参考 [MCP-UI 官网](https://mcpui.dev/)。

ChatKit 为 **MCP-UI/MCP Apps(模型上下文协议 UI)** 提供全面支持,实现 MCP 服务器交互式基于 Web 的 UI 组件的原生移动应用渲染。

**主要功能:**
- ✅ **原生 WebView 渲染** - 安全的沙箱执行以实现 Web 兼容性
- ✅ **一次性操作** - 简单的操作模式(`callTool`、`triggerIntent`、`submitPrompt`、`notify`、`openLink`)
- ✅ **自动调整大小支持** - 通过 `reportSize()` 实现动态内容大小调整
- ✅ **渲染数据注入** - 用于小部件个性化的动态内容注入
- ✅ **安全沙箱** - 具有内容安全策略(CSP)执行的 WebView
- ✅ **多种内容类型** - 支持 HTML(`text/html`)、外部 URL(`text/uri-list`)和远程 DOM 脚本

**用法:**
MCP-UI 小部件会自动在 ChatKit 的对话 UI 中检测并渲染。来自小部件的操作通过对话的委托方法处理。

**JavaScript API(在小部件中):**
```javascript
// 调用后端的工具/函数
window.mcpUI.callTool("search", { query: "example" });

// 触发意图
window.mcpUI.triggerIntent("book_flight", { destination: "NYC" });

// 提交新提示
window.mcpUI.submitPrompt("Tell me more about...");

// 显示通知
window.mcpUI.notify("Operation completed", "success");

// 打开链接
window.mcpUI.openLink("https://example.com");

// 报告小部件大小以进行自动调整大小
window.mcpUI.reportSize(450);
```

### 🎯 A2UI 协议支持

ChatKit 为 **A2UI (Agent to UI) 协议**提供全面支持,实现从 AI 代理生成声明式 UI 组件的原生移动应用渲染。

**主要功能:**
- ✅ **JSONL 流式传输** - 通过 SSE 流式传输 JSON Lines 格式的 A2UI 消息
- ✅ **声明式组件** - 支持标准组件(Text、Button、Row、Column、Card、TextField 等)
- ✅ **数据绑定** - 完整的路径绑定和数据模型更新支持
- ✅ **渐进式渲染** - 流式传输 UI 组件,实现增量更新
- ✅ **扁平组件模型** - 基于邻接表的组件结构,高效渲染

**用法:**
A2UI 消息会自动在 ChatKit 的对话 UI 中检测并渲染。组件通过标准的 A2UI 消息类型(surfaceUpdate、dataModelUpdate、beginRendering)进行更新。

**测试服务器:**
- [a2ui-test-server](../server/a2ui-test-server/) - 完整的 A2UI 测试服务器实现

### 📊 协议比较

| 功能 | AG-UI | OpenAI Bridge | MCP-UI / MCP Apps | A2UI |
|---------|-------|---------------|-------------------|------|
| **目的** | 代理通信的网络协议 | 小部件兼容层 | UI 组件渲染 | 声明式 UI 生成 |
| **API 风格** | SSE + HTTP POST | 基于 Promise(`window.openai`) | 一次性(`window.mcpUI`) | JSONL 流式传输 |
| **状态管理** | 对话级别 | 小部件级别(`setState`/`getState`) | 手动(在小部件中) | 数据模型绑定 |
| **工具调用** | 通过 Sandbox 的完整同意流程 | 基于 Promise 并有响应 | 一次性 | 用户操作事件 |
| **文本流** | ✅ 实时增量 | 不适用 | 不适用 | ✅ 组件流式传输 |
| **多会话** | ✅ 是 | 不适用 | 不适用 | ✅ 是 |
| **最适合** | 代理编排和通信 | OpenAI Apps SDK 小部件 | MCP-UI / MCP Apps 生态系统小部件 | 声明式 UI 生成 |

**集成:** 所有四种约定在 ChatKit 中无缝协作。AG-UI 处理代理通信,而 UI 组件根据类型使用 OpenAI Bridge、MCP-UI / MCP Apps 或 A2UI 支持自动渲染。

