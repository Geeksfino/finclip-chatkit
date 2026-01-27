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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.15/FinClipChatKit.xcframework.zip",
            checksum: "ec11320cc184e94cc7faeb2c517c43f6abc1c5d13eee4536950b5243d9c16586"
        )
    ]
)
