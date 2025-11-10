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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.4.1/ChatKit.xcframework.zip",
            checksum: "ddc7e2ad671d39dc2f55dece2ffa32097e1b2a9cf8ec53f50118f111ba84e62a"
        )
    ]
)
