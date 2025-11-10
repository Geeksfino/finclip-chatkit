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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.5.0/ChatKit.xcframework.zip",
            checksum: "ce92c01a9b6ed2d0023a7b4b04a0928bf8a16a88a2d4f06f7b614962d799c120"
        )
    ]
)
