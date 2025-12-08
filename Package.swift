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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.10/FinClipChatKit.xcframework.zip",
            checksum: "52b2d80457d141416d88301d9c742f43e66a31bf39527d3c9b0f1adec6c6091c"
        )
    ]
)
