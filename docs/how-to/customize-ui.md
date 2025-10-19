# Customize ChatKit UI

ChatKit ships with sensible defaults, but you can tailor the conversation surface for your product.

## 1. Apply Built-In Themes

```swift
ChatKitView(sessionId: sessionId)
  .applyDefaultTheme()
```

Switch to dark mode or brand palettes with custom helpers such as `applyDarkTheme()` or your own extensions.

## 2. Override Appearance via Modifiers

```swift
ChatKitView(sessionId: sessionId)
  .messageBubbleCornerRadius(18)
  .systemMessageStyle(.subheadline)
  .background(Color(.systemGroupedBackground))
```

## 3. Provide Custom Components

Implement `ChatKitComponentFactory` to replace avatars, quick replies, or status indicators:

```swift
struct BrandComponentFactory: ChatKitComponentFactory {
  func makeAvatar(for participant: Participant) -> some View {
    Circle().fill(participant.isBot ? .blue : .green)
  }
}

ChatKit.shared.register(factory: BrandComponentFactory())
```

## 4. Accessibility

- Use `ChatKitView.dynamicTypeSize(_:)` to respect the user’s text size settings.
- Provide `accessibilityLabel` overrides for custom quick reply buttons.

## 5. Explore Further

- `Examples/iOS/MyChatGPT` demonstrates theme overrides in a real app.
- `docs/reference/theme.md` (coming soon) will catalogue available modifiers.
