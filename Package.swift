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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.2.0/ChatKit.xcframework.zip",
            checksum: "dbeb1edff4dd98f6ef7f88d2c18869454d1efba2a87fdf68b6a964035117e544"
        )
    ]
)
