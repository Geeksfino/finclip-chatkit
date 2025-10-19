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
            checksum: "de593fece0f04f3ca413aa62128e0b124d9cb8c8040f6111546ed4e159ebba39"
        )
    ]
)
