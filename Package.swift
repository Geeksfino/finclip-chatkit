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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.6.1/ChatKit.xcframework.zip",
            checksum: "6f79c2647d418ce6c0f4ba4f3a563a59bf68233052fa246eeaebd3df2b421fc2"
        )
    ]
)
