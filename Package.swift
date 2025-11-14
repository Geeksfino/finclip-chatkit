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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.2/FinClipChatKit.xcframework.zip",
            checksum: "c16c6792fa1b06615bdb27655d9baf8a5fa331eefd369633e9a4499b390281c4"
        )
    ]
)
