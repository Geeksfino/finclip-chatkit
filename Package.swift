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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.0/FinClipChatKit.xcframework.zip",
            checksum: "741aad314a80189029ace82a6ad68abacf6d0841f3081b86fec0f867e321025a"
        )
    ]
)
