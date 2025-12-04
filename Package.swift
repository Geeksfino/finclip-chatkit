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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.5/FinClipChatKit.xcframework.zip",
            checksum: "f55f271d1911e10a5fbfceecc1a2625254d7ba73c0910b51277ce51938e4bde3"
        )
    ]
)
