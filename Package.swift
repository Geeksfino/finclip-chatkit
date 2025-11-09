// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ChatKit", targets: ["ChatKit"])
    ],
    targets: [
        .binaryTarget(
            name: "ChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.3.1/ChatKit.xcframework.zip",
            checksum: "0143979cf1273e426c1f7eb9ab2312498acc01e316f4fbe7f47004e6ae0e28c9"
        )
    ]
)
