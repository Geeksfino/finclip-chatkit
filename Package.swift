// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FinClipChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "FinClipChatKit", targets: ["FinClipChatKit"])
    ],
    targets: [
        .binaryTarget(
            name: "FinClipChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.1/FinClipChatKit.xcframework.zip",
            checksum: "521d5d0f6ea413249b6ccaa6aa82f28cead25728c513405090f72b87fc2a58ba"
        )
    ]
)
