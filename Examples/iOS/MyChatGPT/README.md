# MyChatGPT Example App

This SwiftUI example demonstrates how to embed Finclip ChatKit in a native iOS experience.

## Features

- Uses the released `ChatKit` binary via Swift Package Manager.
- Presents a `ChatKitView` with a simple welcome prompt.
- Shows how to theme the conversation surface.

## Requirements

- Xcode 16.0+
- iOS 15 simulator or device

## Setup

```sh
xcodegen generate
open MyChatGPT.xcodeproj
```

Build and run the **MyChatGPT** scheme on your desired destination. Update the package dependency to point at the tagged release of `https://github.com/Geeksfino/finclip-chatkit.git`.
