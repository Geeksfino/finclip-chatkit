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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.3/FinClipChatKit.xcframework.zip",
            checksum: "dd2d7b3a3ce8b7de1c17dbeedf6ec93083d43489eb66727da62c7e6757d129ba"
        )
    ]
)
