# API 层级指南

ChatKit 提供多个 API 层级以适应不同的用例。本指南解释何时使用每个层级以及它们之间的区别。

---

## 概述

ChatKit 提供三种集成方式：

1. **高级 API**（推荐）- 简单、现成的组件
2. **低级 API**（高级）- 最大灵活性，更多样板代码
3. **提供者机制** - 无需更改代码即可自定义框架行为

---

## 高级 API（推荐）

**最适合**：大多数应用、快速开发、标准聊天 UI

高级 API 提供现成的组件，以最少的代码处理最常见的用例。

### 关键组件

#### ChatKitCoordinator
安全地管理运行时生命周期。在应用启动时创建一次。

```swift
let config = NeuronKitConfig.default(serverURL: serverURL)
    .withUserId("user-123")
let coordinator = ChatKitCoordinator(config: config)
```

#### ChatKitConversationManager
自动跟踪多个会话。对于多会话应用是可选的但推荐使用。

```swift
let manager = ChatKitConversationManager()
manager.attach(runtime: coordinator.runtime)
```

#### ChatKitConversationViewController
现成的聊天 UI，具有消息渲染、输入编辑器和所有交互功能。

```swift
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: .default
)
```

#### ChatKitConversationListViewController
现成的会话列表，具有搜索、滑动操作和选择处理功能。

```swift
let listVC = ChatKitConversationListViewController(
    coordinator: coordinator,
    configuration: .default
)
```

### 示例：简单应用模式

**Simple** 示例应用展示了高级 API：

```swift
// 1. 在应用启动时初始化一次
let coordinator = ChatKitCoordinator(config: config)

// 2. 当用户请求时创建会话
let (record, conversation) = try await coordinator.startConversation(
    agentId: agentId,
    title: nil,
    agentName: "My Agent"
)

// 3. 显示现成的聊天 UI
let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

**好处**：
- ✅ 最小化代码（基本聊天仅需 20-30 行）
- ✅ 自动处理所有 UI 交互
- ✅ 一致的行为和样式
- ✅ 内置功能（搜索、滑动操作等）
- ✅ 安全的生命周期管理

**参见**：
- `demo-apps/iOS/Simple/` - Swift 示例
- `demo-apps/iOS/SimpleObjC/` - Objective-C 示例

---

## 低级 API（高级）

**最适合**：自定义 UI 需求、最大控制、非标准布局

低级 API 让您直接访问底层组件，允许完全自定义，但代价是更多样板代码。

### 关键组件

#### 直接 NeuronRuntime 访问
直接访问运行时以进行自定义编排。

```swift
let runtime = coordinator.runtime
// 直接运行时操作
```

#### ChatHostingController + ChatKitAdapter
用于自定义聊天实现的手动 UI 绑定。

```swift
let hosting = ChatHostingController()
let adapter = ChatKitAdapter(chatView: hosting.chatView)
conversation.bindUI(adapter)
```

#### 自定义 UI 实现
使用框架原语构建您自己的 UI。

### 何时使用低级 API

在需要以下情况时使用低级 API：
- 自定义消息渲染
- 非标准 UI 布局
- 专门的交互模式
- 与现有自定义 UI 框架集成

### 权衡

**优点**：
- ✅ 完全控制 UI 和行为
- ✅ 可以与任何 UI 框架集成
- ✅ 最大灵活性

**缺点**：
- ❌ 显著更多的代码（200+ 行 vs 20-30 行）
- ❌ 必须手动处理生命周期
- ❌ 更多样板代码（绑定、解绑、状态管理）
- ❌ 必须自己实现功能（搜索、操作等）
- ❌ 更高的维护负担

### 示例模式

低级实现通常涉及：

1. 创建和管理 `ChatHostingController`
2. 手动绑定/解绑 `ChatKitAdapter`
3. 实现自定义 UI 组件
4. 处理所有生命周期事件
5. 手动管理会话状态

**注意**：框架提供低级 API 以获得最大灵活性，但大多数开发者应使用高级 API。低级 API 冗长且需要大量样板代码。

---

## 提供者机制

**最适合**：在不修改框架代码的情况下自定义框架行为

提供者允许您在特定点向框架注入自定义逻辑。

### 上下文提供者

通过编辑器 UI 将上下文信息（位置、日历事件等）附加到消息。

#### Swift 实现

```swift
import FinClipChatKit
import ConvoUI

class LocationContextProvider: ConvoUIContextProvider {
    func provideContext(completion: @escaping (ConvoUIContext?) -> Void) {
        // 您的位置逻辑
        let context = ConvoUIContext(
            title: "当前位置",
            content: "纬度：37.7749，经度：-122.4194"
        )
        completion(context)
    }
}

// 在 ChatKitConversationConfiguration 中注册
var config = ChatKitConversationConfiguration.default
config.contextProvidersProvider = {
    MainActor.assumeIsolated {
        [
            ConvoUIContextProviderBridge(provider: LocationContextProvider()),
            ConvoUIContextProviderBridge(provider: CalendarContextProvider())
        ]
    }
}
```

#### Objective-C 实现

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyLocationProvider : NSObject <FinConvoComposerContextProvider>
@end

@implementation MyLocationProvider

- (void)provideContextWithCompletion:(void (^)(FinConvoContext * _Nullable))completion {
    // 您的位置逻辑
    FinConvoContext *context = [[FinConvoContext alloc] initWithTitle:@"位置"
                                                               content:@"纬度：37.7749，经度：-122.4194"];
    completion(context);
}

@end

// 通过 ChatKitConversationConfiguration 注册
```

### ASR 提供者

为按住通话语音输入提供自定义自动语音识别。

#### Objective-C 实现

```objc
#import <ConvoUI/ConvoUI.h>

@interface MyASRProvider : NSObject <FinConvoSpeechRecognizer>
@end

@implementation MyASRProvider

- (void)transcribeAudio:(NSURL *)audioFileURL
             completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 您的 ASR 实现（例如，OpenAI Whisper、Google Speech-to-Text）
    // 处理音频并返回转录文本
    completion(transcribedText, nil);
}

- (void)cancelTranscription {
    // 取消任何正在进行的请求
}

@end

// 通过 ChatKitConversationConfiguration 注册
```

**默认**：如果未指定 ASR 提供者，ChatKit 使用 Apple 的 Speech 框架。

### 标题生成提供者

自定义会话标题的生成方式。

#### Swift 实现

```swift
class CustomTitleProvider: ConversationTitleProvider {
    func shouldGenerateTitle(
        sessionId: UUID,
        messageCount: Int,
        currentTitle: String?
    ) async -> Bool {
        // 当应该生成标题时返回 true
        return messageCount >= 3 && currentTitle == nil
    }
    
    func generateTitle(messages: [NeuronMessage]) async throws -> String? {
        // 您的标题生成逻辑（例如，LLM 调用）
        // 使用前几条消息生成标题
        return try await callLLMForTitle(messages: messages)
    }
}

// 创建 ChatKitConversationManager 时注册
let manager = ChatKitConversationManager(titleProvider: CustomTitleProvider())
```

#### Objective-C 实现

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface MyTitleProvider : NSObject <CKTConversationTitleProvider>
@end

@implementation MyTitleProvider

- (void)shouldGenerateTitleForSessionId:(NSString *)sessionId
                           messageCount:(NSInteger)messageCount
                           currentTitle:(NSString *)currentTitle
                             completion:(void (^)(BOOL))completion {
    // 当应该生成标题时返回 YES
    completion(messageCount >= 3 && currentTitle == nil);
}

- (void)generateTitleForSessionId:(NSString *)sessionId
                         messages:(NSArray *)messages
                       completion:(void (^)(NSString * _Nullable, NSError * _Nullable))completion {
    // 您的标题生成逻辑
    // messages 是一个包含消息数据的字典数组
    [self callLLMForTitle:messages completion:^(NSString *title, NSError *error) {
        completion(title, error);
    }];
}

@end

// 创建 CKTConversationManager 时注册
CKTConversationManager *manager = [[CKTConversationManager alloc] initWithTitleProvider:[[MyTitleProvider alloc] init]];
```

**默认**：如果未指定标题提供者，ChatKit 从第一条用户消息中提取标题。

---

## 选择正确的 API 层级

### 如果满足以下条件，使用高级 API：
- ✅ 您想要标准聊天 UI
- ✅ 您想要快速开发
- ✅ 您正在构建典型的聊天应用
- ✅ 您想要最少的代码

**从这里开始**：大多数开发者应使用高级 API。

### 如果满足以下条件，使用低级 API：
- ⚠️ 您需要完全自定义的 UI
- ⚠️ 您正在与现有自定义框架集成
- ⚠️ 您有专门的交互需求
- ⚠️ 您愿意编写显著更多的代码

**警告**：低级 API 需要 10 倍的代码和手动生命周期管理。

### 如果满足以下条件，使用提供者：
- ✅ 您想要自定义特定行为
- ✅ 您需要自定义上下文、ASR 或标题生成
- ✅ 您想要在不修改框架的情况下扩展它

**注意**：提供者与高级和低级 API 都兼容。

---

## 迁移路径

### 从低级 API 到高级 API

如果您当前正在使用低级 API，迁移到高级 API 很简单：

1. 用 `ChatKitConversationViewController` 替换 `ChatHostingController` + `ChatKitAdapter`
2. 使用 `ChatKitCoordinator.startConversation()` 而不是手动创建会话
3. 使用 `ChatKitConversationListViewController` 而不是自定义列表 UI
4. 删除手动绑定/解绑代码

**结果**：代码减少 90%，功能相同。

---

## 示例

### 高级 API 示例
参见：`demo-apps/iOS/Simple/`（Swift）和 `demo-apps/iOS/SimpleObjC/`（Objective-C）

### 低级 API 模式
参见：`demo-apps/iOS/MyChatGPT/`（概念参考 - 展示模式，不推荐给大多数开发者）

---

## 下一步

- **[快速开始指南](./quick-start.zh.md)** - 开始使用高级 API（Swift 和 Objective-C）
- **[组件嵌入指南](./component-embedding.zh.md)** - 学习如何嵌入组件（Swift 和 Objective-C 示例）
- **Swift**：[Swift 开发者指南](./guides/developer-guide.zh.md) - 全面的模式和示例
- **Objective-C**：[Objective-C 开发者指南](./guides/objective-c-guide.zh.md) - 完整的 Objective-C 指南和 API 参考

---

**建议**：从高级 API 开始。它们以最少的代码覆盖 95% 的用例。只有当您有高级 API 无法满足的特定需求时才使用低级 API。

**语言支持**：
- **Swift**：完全支持 async/await 和 Combine
- **Objective-C**：通过带有基于委托模式的 `CKT` 前缀包装类完全支持
