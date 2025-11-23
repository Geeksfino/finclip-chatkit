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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.2/FinClipChatKit.xcframework.zip",
            checksum: "44f548ec9a72443c74cabd2a3adeb12d4790800dfd267b870a5d736cac98dbc9"
        )
    ]
)
