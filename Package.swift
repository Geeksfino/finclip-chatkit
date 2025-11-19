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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.8.0/FinClipChatKit.xcframework.zip",
            checksum: "1314c1f429c24ba2243d7a633da7415f8688c76434916c945af6b6847d8bd1b2"
        )
    ]
)
