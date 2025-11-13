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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.0/ChatKit.xcframework.zip",
            checksum: "20bdb1d0d21b0085d4e853ba8251ba6e9c5dac9756de58ad1577fdd237c4457f"
        )
    ]
)
