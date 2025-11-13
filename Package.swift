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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.6.5/ChatKit.xcframework.zip",
            checksum: "f17350e25cb86014e1c6f5600155c9ea7e7b1a34e8d953f38fa69b8c89bd46c4"
        )
    ]
)
