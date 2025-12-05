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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.8/FinClipChatKit.xcframework.zip",
            checksum: "596965ba8959abdaca05db1e9166b18dc9dee75538f93d1ce3999d7bd470bf1b"
        )
    ]
)
