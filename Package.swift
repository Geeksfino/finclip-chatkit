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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.7/FinClipChatKit.xcframework.zip",
            checksum: "3f24215aafa3c7ac154025222d5f0d3d1ca51dd0c8146e243061bac623187d26"
        )
    ]
)
