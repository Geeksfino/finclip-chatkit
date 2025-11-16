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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.3/FinClipChatKit.xcframework.zip",
            checksum: "9374caedd0faf65dc8f04bfe32b89b710985aead36a2a18edf3248a9c25e299c"
        )
    ]
)
