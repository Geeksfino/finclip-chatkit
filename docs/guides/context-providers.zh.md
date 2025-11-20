# 上下文提供器指南

本指南介绍如何为 ChatKit 实现自定义上下文提供器，允许用户将各种类型的上下文（照片、位置、文件、笔记等）附加到消息中。上下文提供器是"小程序"，让您完全控制收集、预览和显示上下文的用户体验。

> **📘 注意：** 上下文提供器基于 ConvoUI 的上下文提供器系统构建。本指南涵盖 Swift 和 Objective-C 两种实现方式。

---

## 目录

1. [概述](#概述)
2. [架构](#架构)
3. [实现上下文提供器](#实现上下文提供器)
4. [三个组件](#三个组件)
5. [在 ChatKit 中注册](#在-chatkit-中注册)
6. [完整示例](#完整示例)
7. [最佳实践](#最佳实践)
8. [故障排除](#故障排除)

---

## 概述

### 什么是上下文提供器？

上下文提供器使用户能够将丰富的上下文附加到消息中。每个提供器由三个 UI 组件组成：

1. **收集器视图** - 用于选择/创建上下文的 UI（例如，照片选择器、位置地图、文本输入）
2. **预览芯片** - 在输入框中显示的小预览（例如，照片缩略图、位置图标、笔记预览）
3. **详情视图** - 用户点击预览芯片时显示的全屏视图（例如，完整图像、带详细信息的地图、完整笔记）

### 主要优势

- **最大灵活性** - 完全控制所有三个 UI 组件
- **自包含** - 每个提供器都是可重用的"小程序"
- **社区驱动** - 通过 GitHub、Swift Package Manager、CocoaPods 分享提供器
- **框架处理基础工作** - 点击手势、展示、提供器查找全部自动处理
- **与 ChatKit 配合使用** - 与 `ChatKitConversationViewController` 无缝集成

### 使用案例示例

- **照片** - 从图库选择，显示缩略图，全屏预览
- **位置** - 地图选择器，带图标的位置芯片，详细地图视图
- **笔记** - 文本输入，笔记芯片，完整笔记显示
- **股票报价** - 符号选择器，带趋势的价格芯片，详细图表
- **健康指标** - 指标选择器，带颜色编码的值芯片，趋势图
- **视频/音频** - 媒体选择器，带时长的缩略图，播放视图
- **文档** - 文件选择器，图标芯片，文档查看器
- **日历事件** - 日期选择器，事件芯片，完整事件详情

---

## 架构

### 协议结构

ChatKit 使用 ConvoUI 的上下文提供器系统。您需要实现 `ConvoUIContextProvider` 协议：

```swift
@available(iOS 15.0, *)
public protocol ConvoUIContextProvider {
    // 提供器标识
    var id: String { get }
    var title: String { get }
    var iconName: String { get }
    var isAvailable: Bool { get }
    var priority: Int { get }
    var maximumAttachmentCount: Int { get }
    var shouldUseContainerPanel: Bool { get }
    
    // 上下文收集
    func makeContext() async throws -> (any ConvoUIContextItem)?
    func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView?
    
    // 预览和详情
    func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView?
    func localizedDescription(for item: any ConvoUIContextItem) -> String
}
```

### 上下文项结构

每个上下文项代表一个附加的上下文片段：

```swift
@available(iOS 15.0, *)
public protocol ConvoUIContextItem: Identifiable {
    var id: UUID { get }
    var providerId: String { get }  // 链接回提供器
    var type: String { get }        // 例如 "image"、"location"、"note"
    var displayName: String { get }
    
    // 可选自定义预览（如果为 nil，框架使用默认值）
    func createPreviewView(onRemove: @escaping () -> Void) -> UIView?
    
    // 传输编码
    func encodeForTransport() throws -> Data
    var encodingRepresentation: ConvoUIEncodingType { get }
    var encodingMetadata: [String: String]? { get }
}
```

### 框架职责

框架自动处理：

- ✅ **点击手势** - 为预览芯片添加点击处理（包括自定义芯片）
- ✅ **提供器查找** - 点击芯片时通过 `providerId` 查找提供器
- ✅ **展示** - 将详情视图包装在页面表单中
- ✅ **滚动处理** - 确保芯片可滚动同时保持可点击
- ✅ **删除按钮** - 独立处理删除按钮点击
- ✅ **编码** - 发送消息时将编码的上下文发送到后端

---

## 实现上下文提供器

### 步骤 1：创建提供器类

**Swift：**

```swift
import UIKit
import ConvoUI

@available(iOS 15.0, *)
final class MyContextProvider: ConvoUIContextProvider {
    var id: String { "my_provider" }
    var title: String { "My Context" }
    var iconName: String { "star.fill" }
    var isAvailable: Bool { true }
    var priority: Int { 100 }
    var maximumAttachmentCount: Int { 5 }
    var shouldUseContainerPanel: Bool { true }
    
    // 实现下面的方法...
}
```

**Objective-C：**

```objc
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <ConvoUI/FinConvoComposerContextProvider.h>

@interface MyContextProvider : NSObject <FinConvoComposerContextProvider>
@end
```

### 步骤 2：实现上下文收集

选择一种方法：

**选项 A：简单的异步方法**（用于程序化收集）：
```swift
func makeContext() async throws -> (any ConvoUIContextItem)? {
    // 程序化收集上下文
    let data = await collectData()
    return MyContextItem(data: data)
}
```

**选项 B：自定义收集器视图**（用于基于 UI 的收集）：
```swift
func createCollectorView(onConfirm: @escaping ((any ConvoUIContextItem)?) -> Void) -> UIView? {
    let collector = MyCollectorView()
    collector.onConfirm = onConfirm
    return collector
}

func makeContext() async throws -> (any ConvoUIContextItem)? {
    return nil  // 实现 createCollectorView 时不使用
}
```

### 步骤 3：创建上下文项

**Swift：**

```swift
@available(iOS 15.0, *)
struct MyContextItem: ConvoUIContextItem {
    let id = UUID()
    let providerId = "my_provider"  // 必须与 provider.id 匹配
    let type = "my_type"
    var displayName: String { "My Context" }
    
    let data: MyDataType
    
    // 可选：自定义预览芯片
    func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
        // 返回自定义视图，或 nil 使用框架默认值
        return nil
    }
    
    // 编码
    func encodeForTransport() throws -> Data {
        // 为网络传输编码数据
        return try JSONEncoder().encode(data)
    }
    
    var encodingRepresentation: ConvoUIEncodingType { .json }
    var encodingMetadata: [String: String]? { nil }
}
```

**Objective-C：**

```objc
@interface MyContextItem : FinConvoContextItem <FinConvoContextItemEncoding, FinConvoContextItemPreview>
@property (nonatomic, strong) NSString *myData;
@end

@implementation MyContextItem

- (instancetype)initWithData:(NSString *)data {
    self = [super init];
    if (self) {
        _myData = data;
        self.contextId = [[NSUUID UUID] UUIDString];
        self.contextType = @"my_type";
        self.providerId = @"my_provider";
        self.displayName = @"My Context";
        
        // ⚠️ 关键：设置编码处理器，以便框架使用您的编码方法
        // 没有这个，上下文项不会被编码，也不会发送到后端！
        self.encodingHandler = self;
        
        // ⚠️ 关键：如果使用自定义预览视图，设置预览处理器
        self.previewHandler = self;
    }
    return self;
}

// 实现编码方法
- (NSData *)encodeForTransport:(NSError **)error {
    NSDictionary *payload = @{ @"data": self.myData };
    return [NSJSONSerialization dataWithJSONObject:payload options:0 error:error];
}

- (FinConvoContextEncoding)encodingRepresentation {
    return FinConvoContextEncodingJSON;
}

@end
```

**⚠️ Objective-C 的关键点：** 您**必须**在初始化器中设置 `self.encodingHandler = self;`。没有这个，框架将不会编码您的上下文项，也不会发送到后端！

### 步骤 4：实现详情视图

```swift
func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
    guard let myItem = item as? MyContextItem else { return nil }
    
    let detailView = MyDetailView(item: myItem)
    detailView.onDismiss = onDismiss
    
    // 如果使用视图控制器，保留它：
    // let controller = MyDetailViewController(item: myItem, onDismiss: onDismiss)
    // objc_setAssociatedObject(controller.view, "viewController", controller, .OBJC_ASSOCIATION_RETAIN)
    // return controller.view
    
    return detailView
}
```

---

## 在 ChatKit 中注册

### Swift：使用 ChatKitConversationConfiguration

```swift
import FinClipChatKit
import ConvoUI

final class ChatViewController: ChatKitConversationViewController {
    init(record: ConversationRecord, conversation: Conversation, coordinator: ChatKitCoordinator) {
        var config = ChatKitConversationConfiguration.default
        config.showStatusBanner = true
        config.showWelcomeMessage = true
        
        // 注册上下文提供器
        config.contextProvidersProvider = {
            MainActor.assumeIsolated {
                [
                    ConvoUIContextProviderBridge(provider: LocationContextProvider()),
                    ConvoUIContextProviderBridge(provider: CalendarContextProvider()),
                    ConvoUIContextProviderBridge(provider: MyContextProvider())
                ]
            }
        }
        
        super.init(record: record, conversation: conversation, coordinator: coordinator, configuration: config)
    }
}
```

### Objective-C：直接注册

由于 `CKTConversationConfiguration` 不暴露 `contextProvidersProvider`（它是 Swift 闭包），直接在聊天视图上注册提供器：

```objc
#import "MyContextProvider.h"
#import <FinClipChatKit/FinClipChatKit-Swift.h>
#import <ConvoUI/FinConvoMessageInputView.h>

// 创建 ChatKitConversationViewController 后：
ChatKitConversationViewController *chatVC = [[ChatKitConversationViewController alloc] 
    initWithObjCRecord:record
    conversation:conversation
    objcCoordinator:coordinator
    objcConfiguration:config];

// 直接在聊天视图上注册上下文提供器
dispatch_async(dispatch_get_main_queue(), ^{
    // 如果需要，加载视图以确保 chatView 可用
    [chatVC loadViewIfNeeded];
    
    if (@available(iOS 15.0, *)) {
        MyContextProvider *myProvider = [[MyContextProvider alloc] init];
        chatVC.chatView.inputView.contextProviders = @[myProvider];
        chatVC.chatView.inputView.contextPickerEnabled = YES;
        chatVC.chatView.inputView.contextPickerMaxItems = 3;
    }
    [self.navigationController pushViewController:chatVC animated:YES];
});
```

---

## 三个组件

### 1. 收集器视图

收集器视图在用户从上下文选择器菜单中选择您的提供器时显示。

**何时使用 `createCollectorView`：**
- 用户需要与 UI 交互以选择上下文
- 示例：照片选择器、地图选择器、文件浏览器、日期选择器、文本输入

**何时使用 `makeContext`：**
- 可以程序化收集上下文
- 示例：当前位置、设备信息、剪贴板内容

**收集器视图示例（Swift）：**

```swift
class MyCollectorView: UIView {
    var onConfirm: (((any ConvoUIContextItem)?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // 添加您的 UI 组件
        let button = UIButton(type: .system)
        button.setTitle("Select Context", for: .normal)
        button.addTarget(self, action: #selector(handleSelect), for: .touchUpInside)
        addSubview(button)
        
        // 布局...
    }
    
    @objc private func handleSelect() {
        // 创建上下文项
        let item = MyContextItem(data: collectedData)
        onConfirm?(item)
    }
}
```

### 2. 预览芯片

预览芯片出现在输入框上方的输入区域，显示附加的上下文。

**框架默认行为：**

如果 `createPreviewView` 返回 `nil`，框架提供默认值：

- **图像类型** (`type == "image"`)：44x44 缩略图，带删除按钮
- **其他类型**：带 `displayName` 和删除按钮的文本芯片

**自定义预览：**

返回自定义视图以进行独特样式设计。框架自动添加点击处理：

```swift
func createPreviewView(onRemove: @escaping () -> Void) -> UIView? {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
    container.backgroundColor = .systemBlue.withAlphaComponent(0.1)
    container.layer.cornerRadius = 8
    
    // 图标
    let icon = UILabel(frame: CGRect(x: 8, y: 10, width: 20, height: 20))
    icon.text = "📍"
    container.addSubview(icon)
    
    // 标签
    let label = UILabel(frame: CGRect(x: 32, y: 0, width: 40, height: 40))
    label.text = displayName
    container.addSubview(label)
    
    // 删除按钮
    let removeButton = UIButton(type: .system)
    removeButton.frame = CGRect(x: 60, y: 10, width: 20, height: 20)
    removeButton.setTitle("✕", for: .normal)
    removeButton.addAction(UIAction { _ in onRemove() }, for: .touchUpInside)
    container.addSubview(removeButton)
    
    return container
}
```

**重要提示：**

- ✅ 框架自动添加点击手势以打开详情视图
- ✅ 框架处理滚动视图交互
- ✅ 删除按钮独立工作
- ✅ 无需自己管理点击手势

### 3. 详情视图

详情视图在用户点击预览芯片时显示。

**简单 UIView 方法：**

```swift
class MyDetailView: UIView {
    var onDismiss: (() -> Void)?
    
    init(item: MyContextItem) {
        super.init(frame: .zero)
        setupUI(item: item)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(item: MyContextItem) {
        backgroundColor = .systemBackground
        
        // 关闭按钮
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        addSubview(closeButton)
        
        // 您的内容
        // ...
        
        // 布局...
    }
    
    @objc private func handleClose() {
        onDismiss?()
    }
}
```

**UIViewController 方法：**

如果您需要视图控制器生命周期：

```swift
class MyDetailViewController: UIViewController {
    private let onDismiss: () -> Void
    
    init(item: MyContextItem, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        setupUI(item: item)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(item: MyContextItem) {
        view.backgroundColor = .systemBackground
        // 设置 UI...
    }
    
    @objc private func handleClose() {
        onDismiss()
    }
}

// 在提供器中：
func createDetailView(for item: any ConvoUIContextItem, onDismiss: @escaping () -> Void) -> UIView? {
    guard let myItem = item as? MyContextItem else { return nil }
    
    let controller = MyDetailViewController(item: myItem, onDismiss: onDismiss)
    
    // 关键：保留控制器
    objc_setAssociatedObject(controller.view, "viewController", controller, .OBJC_ASSOCIATION_RETAIN)
    
    return controller.view
}
```

---

## 完整示例

### Swift 示例

**位置提供器：**
- 参见 `demo-apps/iOS/Simple/App/Extensions/LocationContextProvider.swift`
- 带 `MKMapView` 和搜索的自定义收集器视图
- 带 📍 图标的自定义预览芯片
- 带地图的自定义详情视图

**日历提供器：**
- 参见 `demo-apps/iOS/Simple/App/Extensions/CalendarContextProvider.swift`
- 带事件列表的自定义收集器视图
- 带日历图标的自定义预览芯片
- 带事件详情的自定义详情视图

### Objective-C 示例

**笔记提供器：**
- 参见 `demo-apps/iOS/SimpleObjC/App/ContextProviders/NoteContextProvider.h/m`
- 完整的 Objective-C 实现，演示：
  - 自定义收集器视图（文本输入）
  - 自定义预览芯片（样式化笔记预览）
  - 自定义详情视图（完整笔记显示）
  - 正确设置 `encodingHandler` 的编码
  - 在 `ConversationListViewController` 中注册

---

## 最佳实践

### 1. 提供器标识

**始终设置唯一的 `providerId`：**

```swift
// 在提供器中
var id: String { "my_unique_provider_id" }

// 在上下文项中
let providerId = "my_unique_provider_id"  // 必须匹配！
```

这确保框架在显示详情视图时能正确匹配项到提供器。

### 2. 编码处理器（关键！）

**⚠️ 最常见问题：** 上下文项未发送到后端。

**对于 Swift：** 当您实现 `ConvoUIContextItem` 时，框架自动使用您的编码方法。

**对于 Objective-C：** 您**必须**设置 `encodingHandler` 属性：

```objc
// 在您的上下文项的 init 方法中：
self.encodingHandler = self;  // 编码工作所必需！
```

**为什么需要这个：**

框架检查 `item.encodingHandler` 以确定是否应编码上下文项。如果 `encodingHandler` 为 `nil`，框架假定项不需要编码，不会调用您的 `encodeForTransport:` 方法。

**验证清单：**

- ✅ 在初始化器中设置 `encodingHandler` 为 `self`（Objective-C）
- ✅ 上下文项符合 `FinConvoContextItemEncoding` 协议（Objective-C）或 `ConvoUIContextItem`（Swift）
- ✅ `encodeForTransport:` 返回有效的 `NSData`（Objective-C）或 `Data`（Swift）
- ✅ `encodingRepresentation` 返回正确的编码类型
- ✅ 通过发送消息并检查后端是否收到上下文来测试

### 3. 预览芯片设计

**指南：**
- 保持芯片紧凑（36-80pt 宽度，36-44pt 高度）
- 使用清晰的视觉指示器（图标、颜色）
- 确保删除按钮易于点击
- 在滚动视图中测试（芯片水平滚动）

**无障碍性：**
- 在自定义预览视图上设置 `accessibilityLabel`
- 确保足够的对比度
- 如果使用文本，支持动态类型

### 4. 详情视图生命周期

**如果使用 UIViewController：**
- 始终使用 `objc_setAssociatedObject` 保留控制器
- 用户关闭时调用 `onDismiss()`
- 不要自己以模态方式展示（框架处理）

**如果使用 UIView：**
- 实现 `onDismiss` 回调
- 正确处理布局约束
- 支持安全区域

### 5. 错误处理

**收集错误：**
```swift
func makeContext() async throws -> (any ConvoUIContextItem)? {
    do {
        let data = try await collectData()
        return MyContextItem(data: data)
    } catch {
        // 记录错误、显示警报或返回 nil
        return nil
    }
}
```

### 6. 性能

**延迟加载：**
- 在显示详情视图之前不要加载大量数据
- 预览芯片使用缩略图
- 编码前压缩图像

**内存管理：**
- 详情视图关闭时释放资源
- 在闭包中使用弱引用
- 适当清除缓存

### 7. 本地化

**提供器元数据：**
```swift
var title: String { 
    NSLocalizedString("context.my_provider", comment: "My Provider")
}
```

**上下文描述：**
```swift
func localizedDescription(for item: any ConvoUIContextItem) -> String {
    // 返回用于后备文本预览的本地化描述
    return NSLocalizedString("context.my_provider.description", comment: "")
}
```

---

## 故障排除

### 预览芯片不可点击

**问题：** 点击预览芯片不会打开详情视图。

**解决方案：**
- 确保 `providerId` 在提供器和项之间匹配
- 检查 `createDetailView` 是否返回非 nil 视图
- 验证框架是否已添加点击手势（检查日志）
- 确保自定义预览视图的 `userInteractionEnabled = true`

### 详情视图未显示

**问题：** 点击芯片时详情视图不出现。

**解决方案：**
- 检查提供器查找日志以验证是否找到提供器
- 确保实现了 `createDetailView`
- 如果使用 UIViewController，验证控制器是否已保留
- 检查 `onDismiss` 回调是否正确连接

### 自定义预览未出现

**问题：** 未显示自定义预览芯片，而是使用默认值。

**解决方案：**
- 验证 `createPreviewView` 是否返回非 nil 视图
- 检查视图是否有有效的框架或约束
- 确保在返回之前正确配置视图
- 首先使用框架的默认值进行测试，然后添加自定义

### 删除按钮不工作

**问题：** 删除按钮（×）不会删除上下文项。

**解决方案：**
- 验证 `onRemove` 回调是否被调用
- 检查按钮是否被其他视图覆盖
- 确保按钮已添加到预览视图层次结构中
- 首先使用框架的默认预览进行测试

### 提供器不在菜单中

**问题：** 提供器未出现在上下文选择器菜单中。

**解决方案：**
- 检查 `isAvailable` 是否返回 `true`
- 验证提供器是否已添加到 `contextProviders` 数组
- 确保 `contextPickerEnabled` 为 `true`
- 检查 `priority` 值（越高 = 越先出现）

### 上下文未发送到后端

**问题：** 上下文项出现在 UI 中，但未包含在发送到后端的消息中。

**解决方案：**
- **Objective-C：** 验证 `encodingHandler` 是否在上下文项的初始化器中设置为 `self`
- 检查上下文项是否符合 `FinConvoContextItemEncoding` 协议（Objective-C）或 `ConvoUIContextItem`（Swift）
- 验证 `encodeForTransport:` 方法是否返回有效的 `NSData`（不为 nil）
- 检查 `encodingRepresentation` 是否返回正确的编码类型
- 直接测试编码方法：`NSData *data = [item.encodingHandler encodeForTransport:&error];`（Objective-C）
- 检查框架日志中的编码错误
- 验证发送消息时 `item.encodingHandler` 不为 `nil`（Objective-C）

**常见错误：**
- ❌ 在 Objective-C 中忘记设置 `self.encodingHandler = self;`
- ❌ `encodeForTransport:` 返回 `nil` 或抛出错误
- ❌ 不符合 `FinConvoContextItemEncoding` 协议（Objective-C）
- ❌ 在创建项后设置 `encodingHandler`（必须在 `init` 中）

---

## 相关文档

- **[开发者指南](./developer-guide.zh.md)** - 完整的 ChatKit 开发指南
- **[Objective-C 指南](./objective-c-guide.zh.md)** - Objective-C 特定模式
- **[UI 自定义](../../how-to/customize-ui.zh.md)** - 输入框功能概述
- **[示例](../../../demo-apps/iOS/)** - 演示应用中的工作示例

---

## 演示应用

完整的工作示例可在演示应用中找到：

- **Simple (Swift)：** `demo-apps/iOS/Simple/App/Extensions/`
  - `LocationContextProvider.swift`
  - `CalendarContextProvider.swift`
  
- **SimpleObjC (Objective-C)：** `demo-apps/iOS/SimpleObjC/App/ContextProviders/`
  - `NoteContextProvider.h/m` - 完整的 Objective-C 示例

---

**最后更新**：2025 年 11 月  
**ChatKit 版本**：0.9.0+

