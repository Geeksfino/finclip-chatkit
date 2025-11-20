# 提示启动器指南

本指南介绍如何在 ChatKit 中实现和配置提示启动器。提示启动器是显示在新对话顶部的预定义建议芯片，帮助用户快速开始与 AI 助手交互。

> **📘 注意：** 提示启动器基于 ConvoUI 的提示启动器系统构建。本指南涵盖使用 ChatKit API 的 Swift 和 Objective-C 两种实现方式。

---

## 目录

1. [概述](#概述)
2. [快速开始](#快速开始)
3. [使用 ChatKit API](#使用-chatkit-api)
4. [自定义启动器](#自定义启动器)
5. [样式设置](#样式设置)
6. [高级用法](#高级用法)
7. [最佳实践](#最佳实践)
8. [故障排除](#故障排除)

---

## 概述

### 什么是提示启动器？

提示启动器是显示在消息列表顶部的水平滚动芯片，在以下情况下显示：
- 聊天视图新初始化
- 对话中有 0 条用户消息
- 通过 SDK 配置

一旦用户发送第一条消息或点击启动器，启动器会自动隐藏，并且在当前会话中不会再次出现。

### 主要优势

- **更好的用户体验** - 引导用户进行有意义的交互
- **减少摩擦** - 帮助用户快速开始
- **可自定义** - 完全控制内容、样式和行为
- **自动管理** - 框架处理可见性和生命周期

### 使用案例示例

- **通用聊天** - "帮我做点什么"、"头脑风暴"、"解释某事"
- **邮件助手** - "写一封专业邮件"、"起草会议请求"
- **创意工具** - "生成故事"、"创作诗歌"、"设计徽标概念"
- **生产力** - "规划我的一天"、"总结文档"、"设置提醒"

---

## 快速开始

### Swift：使用工厂方法

最简单的方法是使用 `ChatKitPromptStarterFactory`：

```swift
import FinClipChatKit
import ConvoUI

var config = ChatKitConversationConfiguration.default
config.showStatusBanner = true
config.showWelcomeMessage = true

// 使用工厂方法创建常见启动器
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}

let chatVC = ChatKitConversationViewController(
    record: record,
    conversation: conversation,
    coordinator: coordinator,
    configuration: config
)
```

### Objective-C：使用工厂方法

```objc
#import <FinClipChatKit/FinClipChatKit-Swift.h>

CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
config.showStatusBanner = YES;
config.showWelcomeMessage = YES;

// 使用工厂方法创建常见启动器
config.promptStartersProvider = ^NSArray * _Nonnull {
    return [ChatKitPromptStarterFactory createExampleStarters];
};

ChatKitConversationViewController *chatVC = 
    [[ChatKitConversationViewController alloc] initWithObjCRecord:record
                                                     conversation:conversation
                                                  objcCoordinator:coordinator
                                                objcConfiguration:config];
```

---

## 使用 ChatKit API

### ChatKitPromptStarterFactory

ChatKit 提供了一个工厂类，包含预配置的启动器集合：

#### 可用的工厂方法

**1. `createDefaultStarters()`** - 适用于通用聊天应用的平衡集合：

```swift
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createDefaultStarters()
}
```

返回：
- "帮我做点什么"（questionmark.circle.fill 图标）
- "头脑风暴"（lightbulb.fill 图标，"创造性思维" 副标题）
- "解释某事"（book.fill 图标，"简单分解" 副标题）

**2. `createExampleStarters()`** - 类似 ChatGPT 的丰富集合：

```swift
config.promptStartersProvider = {
    ChatKitPromptStarterFactory.createExampleStarters()
}
```

返回：
- "写一封专业邮件"（envelope.fill 图标）
- "帮我头脑风暴"（lightbulb.fill 图标，"创造性思维和问题解决" 副标题）
- "解释复杂主题"（book.fill 图标，"简单分解" 副标题）
- "高效规划我的一天"（calendar 图标）

### ChatKitConversationConfiguration

通过 `ChatKitConversationConfiguration` 配置提示启动器：

```swift
var config = ChatKitConversationConfiguration.default

// 设置提示启动器提供器
config.promptStartersProvider = {
    // 返回 FinConvoPromptStarter 数组
    return ChatKitPromptStarterFactory.createExampleStarters()
}

// 可选：处理启动器选择
config.onPromptStarterSelected = { starter in
    print("选择的启动器：\(starter.starterId)")
    // 返回 false 自动发送，true 阻止自动发送
    return false
}

// 可选：自定义样式
let style = FinConvoPromptStarterStyle()
style.backgroundColor = .systemBlue
style.textColor = .white
style.cornerRadius = 25.0
config.promptStarterStyle = style
```

---

## 自定义启动器

### 创建自定义启动器（Swift）

```swift
config.promptStartersProvider = {
    [
        FinConvoPromptStarter(
            starterId: "email",
            title: "写一封专业邮件",
            subtitle: nil,
            icon: UIImage(systemName: "envelope.fill"),
            payload: nil
        ),
        FinConvoPromptStarter(
            starterId: "brainstorm",
            title: "帮我头脑风暴",
            subtitle: "创造性思维",
            icon: UIImage(systemName: "lightbulb.fill"),
            payload: nil
        ),
        FinConvoPromptStarter(
            starterId: "explain",
            title: "解释复杂主题",
            subtitle: "简单分解",
            icon: UIImage(systemName: "book.fill"),
            payload: ["category": "education"]
        )
    ]
}
```

### 创建自定义启动器（Objective-C）

```objc
config.promptStartersProvider = ^NSArray * _Nonnull {
    FinConvoPromptStarter *starter1 = [[FinConvoPromptStarter alloc] 
        initWithStarterId:@"email"
        title:@"写一封专业邮件"
        subtitle:nil
        icon:[UIImage systemImageNamed:@"envelope.fill"]
        payload:nil];
    
    FinConvoPromptStarter *starter2 = [[FinConvoPromptStarter alloc] 
        initWithStarterId:@"brainstorm"
        title:@"帮我头脑风暴"
        subtitle:@"创造性思维"
        icon:[UIImage systemImageNamed:@"lightbulb.fill"]
        payload:nil];
    
    return @[starter1, starter2];
};
```

### FinConvoPromptStarter 属性

- **`starterId`** (String) - 启动器的唯一标识符
- **`title`** (String) - 显示在芯片上的主要文本（必需）
- **`subtitle`** (String?) - 可选的副标题文本
- **`icon`** (UIImage?) - 可选的图标图像
- **`payload`** (Any?) - 可选的开发者元数据

---

## 样式设置

### 使用 FinConvoPromptStarterStyle

自定义提示启动器芯片的外观：

```swift
let style = FinConvoPromptStarterStyle()

// 颜色
style.backgroundColor = .systemBlue
style.textColor = .white
style.subtitleTextColor = .systemGray

// 字体
style.titleFont = UIFont.boldSystemFont(ofSize: 16)
style.subtitleFont = UIFont.systemFont(ofSize: 13)

// 布局
style.cornerRadius = 25.0
style.horizontalSpacing = 12.0
style.verticalSpacing = 12.0
style.contentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
style.minimumHeight = 44.0

// 图标
style.iconSize = CGSize(width: 20, height: 20)

config.promptStarterStyle = style
```

### Objective-C 样式设置

```objc
FinConvoPromptStarterStyle *style = [[FinConvoPromptStarterStyle alloc] init];
style.backgroundColor = [UIColor systemBlueColor];
style.textColor = [UIColor whiteColor];
style.cornerRadius = 25.0;
style.titleFont = [UIFont boldSystemFontOfSize:16];

config.promptStarterStyle = style;
```

### 默认样式

如果未提供自定义样式，框架使用类似 ChatGPT 的默认样式：
- 背景：`systemGray5`
- 文本：`systemLabel`
- 圆角半径：`20.0`
- 字体：系统字体，标题 15pt 中等，副标题 13pt 常规

---

## 高级用法

### 自定义选择处理

拦截启动器选择以添加自定义逻辑：

```swift
config.onPromptStarterSelected = { starter in
    // 记录分析
    Analytics.track("prompt_starter_selected", properties: [
        "starter_id": starter.starterId,
        "title": starter.title
    ])
    
    // 特定启动器的自定义处理
    if starter.starterId == "special-starter" {
        // 执行特殊操作
        handleSpecialStarter(starter)
        return true // 阻止自动发送
    }
    
    // 默认：自动将启动器标题作为消息发送
    return false
}
```

### Objective-C 选择处理

```objc
config.onPromptStarterSelected = ^BOOL(FinConvoPromptStarter *starter) {
    NSLog(@"选择的启动器：%@", starter.starterId);
    
    // 自定义逻辑
    if ([starter.starterId isEqualToString:@"special-starter"]) {
        [self handleSpecialStarter:starter];
        return YES; // 阻止自动发送
    }
    
    return NO; // 允许自动发送
};
```

### 动态启动器

根据上下文更新启动器：

```swift
class ChatViewController: ChatKitConversationViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 根据用户上下文更新启动器
        updatePromptStarters()
    }
    
    private func updatePromptStarters() {
        let starters: [FinConvoPromptStarter]
        
        if userIsPremium {
            starters = createPremiumStarters()
        } else {
            starters = ChatKitPromptStarterFactory.createDefaultStarters()
        }
        
        chatView.setPromptStarters(starters)
    }
}
```

### 使用 Payload 存储元数据

在启动器中存储自定义数据：

```swift
let starter = FinConvoPromptStarter(
    starterId: "email",
    title: "写一封专业邮件",
    subtitle: nil,
    icon: UIImage(systemName: "envelope.fill"),
    payload: [
        "category": "productivity",
        "difficulty": "easy",
        "estimatedTime": 2
    ]
)

// 在选择处理程序中访问 payload
config.onPromptStarterSelected = { starter in
    if let payload = starter.payload as? [String: Any],
       let category = payload["category"] as? String {
        print("类别：\(category)")
    }
    return false
}
```

---

## 最佳实践

### 1. 保持标题简洁

**好的：**
- "写一封专业邮件"
- "帮我头脑风暴"
- "解释复杂主题"

**避免：**
- "我希望您帮我写一封专业邮件"（太长）
- "邮件"（太模糊）

### 2. 使用清晰的动作动词

以动作动词开头：
- ✅ "写"、"解释"、"帮助"、"创建"、"规划"、"总结"
- ❌ "关于"、"信息"、"详情"

### 3. 最佳数量

- **3-6 个启动器**是最佳的
- 太少（1-2 个）：选项有限
- 太多（7+ 个）：令人不知所措，滚动困难

### 4. 使其具体

**好的：**
- "写一封专业邮件"
- "高效规划我的一天"
- "简单解释量子物理"

**避免：**
- "邮件"（太通用）
- "帮助"（不够具体）

### 5. 策略性使用副标题

副标题适用于：
- 澄清启动器的目的
- 添加上下文或示例
- 解释预期结果

```swift
FinConvoPromptStarter(
    starterId: "brainstorm",
    title: "帮我头脑风暴",
    subtitle: "创造性思维和问题解决", // 增加清晰度
    icon: UIImage(systemName: "lightbulb.fill"),
    payload: nil
)
```

### 6. 选择适当的图标

使用与启动器目的匹配的 SF Symbols：
- 📧 `envelope.fill` 用于邮件
- 💡 `lightbulb.fill` 用于头脑风暴
- 📖 `book.fill` 用于解释
- 📅 `calendar` 用于规划
- ✍️ `pencil` 用于写作

### 7. 在不同屏幕尺寸上测试

确保水平滚动在以下设备上正常工作：
- iPhone SE（小屏幕）
- iPhone Pro Max（大屏幕）
- iPad（超宽屏幕）

### 8. 考虑本地化

为国际用户提供本地化标题：

```swift
config.promptStartersProvider = {
    [
        FinConvoPromptStarter(
            starterId: "email",
            title: NSLocalizedString("prompt_starter.email", comment: "写一封专业邮件"),
            subtitle: nil,
            icon: UIImage(systemName: "envelope.fill"),
            payload: nil
        )
    ]
}
```

---

## 故障排除

### 启动器未显示

**问题：** 提示启动器未出现在聊天视图中。

**解决方案：**
- ✅ 验证 `promptStartersProvider` 是否在配置中设置
- ✅ 检查对话是否有 0 条用户消息（启动器仅在新对话中显示）
- ✅ 确保启动器数组不为空
- ✅ 验证配置是否传递给 `ChatKitConversationViewController` 初始化器

### 启动器未隐藏

**问题：** 发送消息后启动器仍然可见。

**解决方案：**
- ✅ 这应该自动发生 - 检查框架日志
- ✅ 验证消息是否实际发送（检查对话状态）
- ✅ 确保在消息发送后没有手动显示启动器

### 自定义回调未调用

**问题：** `onPromptStarterSelected` 回调未调用。

**解决方案：**
- ✅ 验证回调是否在视图控制器初始化之前设置在配置上
- ✅ 检查回调签名是否匹配预期类型：`(FinConvoPromptStarter) -> Bool`
- ✅ 确保回调不为 `nil`

### 样式未应用

**问题：** 自定义样式设置未在 UI 中反映。

**解决方案：**
- ✅ 验证 `promptStarterStyle` 是否在视图控制器初始化之前设置
- ✅ 检查样式属性是否正确设置
- ✅ 确保样式对象不为 `nil`

### Objective-C：找不到工厂方法

**问题：** `ChatKitPromptStarterFactory` 方法在 Objective-C 中不可访问。

**解决方案：**
- ✅ 确保导入：`#import <FinClipChatKit/FinClipChatKit-Swift.h>`
- ✅ 使用 `@objc` 暴露的方法：`createDefaultStarters()` 和 `createExampleStarters()`
- ✅ 检查是否使用正确的工厂类名

---

## 示例

### 完整的 Swift 示例

```swift
import UIKit
import FinClipChatKit
import ConvoUI

final class ChatViewController: ChatKitConversationViewController {
    init(record: ConversationRecord, conversation: Conversation, coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationConfiguration.default
        config.showStatusBanner = true
        config.showWelcomeMessage = true
        config.welcomeMessageProvider = { "你好！今天我能为您做些什么？" }
        
        // 配置提示启动器
        config.promptStartersProvider = {
            ChatKitPromptStarterFactory.createExampleStarters()
        }
        
        // 处理启动器选择
        config.onPromptStarterSelected = { starter in
            print("用户选择：\(starter.title)")
            // 返回 false 自动发送，true 阻止
            return false
        }
        
        // 自定义样式
        let style = FinConvoPromptStarterStyle()
        style.backgroundColor = .systemBlue
        style.textColor = .white
        style.cornerRadius = 25.0
        config.promptStarterStyle = style
        
        super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
```

### 完整的 Objective-C 示例

```objc
#import <UIKit/UIKit.h>
#import <FinClipChatKit/FinClipChatKit-Swift.h>

@interface ChatViewController : ChatKitConversationViewController
@end

@implementation ChatViewController

- (instancetype)initWithRecord:(CKTConversationRecord *)record 
                  conversation:(id)conversation 
                   coordinator:(CKTChatKitCoordinator *)coordinator {
    CKTConversationConfiguration *config = [CKTConversationConfiguration defaultConfiguration];
    config.showStatusBanner = YES;
    config.showWelcomeMessage = YES;
    config.welcomeMessageProvider = ^NSString * _Nullable {
        return @"你好！今天我能为您做些什么？";
    };
    
    // 配置提示启动器
    config.promptStartersProvider = ^NSArray * _Nonnull {
        return [ChatKitPromptStarterFactory createExampleStarters];
    };
    
    // 处理启动器选择
    config.onPromptStarterSelected = ^BOOL(FinConvoPromptStarter *starter) {
        NSLog(@"用户选择：%@", starter.title);
        return NO; // 允许自动发送
    };
    
    // 自定义样式
    FinConvoPromptStarterStyle *style = [[FinConvoPromptStarterStyle alloc] init];
    style.backgroundColor = [UIColor systemBlueColor];
    style.textColor = [UIColor whiteColor];
    style.cornerRadius = 25.0;
    config.promptStarterStyle = style;
    
    self = [super initWithObjCRecord:record
                         conversation:conversation
                      objcCoordinator:coordinator
                    objcConfiguration:config];
    return self;
}

@end
```

---

## 相关文档

- **[开发者指南](./developer-guide.zh.md)** - 完整的 ChatKit 开发指南
- **[Objective-C 指南](./objective-c-guide.zh.md)** - Objective-C 特定模式
- **[上下文提供器指南](./context-providers.zh.md)** - 向消息添加上下文
- **[组件嵌入](../component-embedding.zh.md)** - 嵌入聊天组件

---

## 演示应用

工作示例可在演示应用中找到：

- **Simple (Swift)：** 参见 `demo-apps/iOS/Simple/App/ViewControllers/ChatViewController.swift`
- **MyChatGPT：** 参见 `chatkit/Examples/MyChatGPT/` 获取完整的提示启动器实现

---

**最后更新**：2025 年 11 月  
**ChatKit 版本**：0.9.0+

