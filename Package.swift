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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.4/FinClipChatKit.xcframework.zip",
            checksum: "ad0623f71c80e1177e2b862d32c2e06e4c8e0a1ecf0d2110ed599281c4b1f056"
        )
    ]
)
