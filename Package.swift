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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.4/FinClipChatKit.xcframework.zip",
            checksum: "816747d0af13c54a96602f6be56835304e12d0f8ebac17ede22148c74b2cf1f0"
        )
    ]
)
