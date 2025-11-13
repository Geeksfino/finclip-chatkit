# 自定义 ChatKit UI

ChatKit 提供了合理的默认设置，但您可以为您的产品定制会话界面。

## 1. 应用内置主题

```swift
ChatKitView(sessionId: sessionId)
  .applyDefaultTheme()
```

使用自定义辅助方法（如 `applyDarkTheme()`）或您自己的扩展来切换到深色模式或品牌调色板。

## 2. 通过修饰符覆盖外观

```swift
ChatKitView(sessionId: sessionId)
  .messageBubbleCornerRadius(18)
  .systemMessageStyle(.subheadline)
  .background(Color(.systemGroupedBackground))
```

## 3. 提供自定义组件

实现 `ChatKitComponentFactory` 以替换头像、快捷回复或状态指示器：

```swift
struct BrandComponentFactory: ChatKitComponentFactory {
  func makeAvatar(for participant: Participant) -> some View {
    Circle().fill(participant.isBot ? .blue : .green)
  }
}

ChatKit.shared.register(factory: BrandComponentFactory())
```

## 4. 无障碍访问

- 使用 `ChatKitView.dynamicTypeSize(_:)` 来尊重用户的文本大小设置。
- 为自定义快捷回复按钮提供 `accessibilityLabel` 覆盖。

## 5. 进一步探索

- `Examples/iOS/MyChatGPT` 演示了在真实应用中的主题覆盖。
- `docs/reference/theme.md`（即将推出）将列出可用的修饰符。
