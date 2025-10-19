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
            checksum: "501d3e68557c9113bffd64c8c2d28aa1980a8d68cac6c37ceb2537ef1ef5bef4"
        )
    ]
)
