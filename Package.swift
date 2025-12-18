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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.12/FinClipChatKit.xcframework.zip",
            checksum: "95cf892c5a2520d7d3946bdcef615148d25a05115fb85cbc5ca756fdf168f9a9"
        )
    ]
)
