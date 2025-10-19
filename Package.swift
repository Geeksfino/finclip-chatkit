// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "ChatKit",
            type: .binary,
            targets: ["ChatKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.0.1/ChatKit.xcframework.zip",
            checksum: "e96d580d4b9fbbde7cbff17b91806352600595a18aa334741573853b995cfc19"
        )
    ]
)
