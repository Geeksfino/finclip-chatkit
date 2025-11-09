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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.3.0/ChatKit.xcframework.zip",
            checksum: "5fba49105cf2d9ba737d575ad709ccd7f8169a91fa8375a4768f54c2458208f2"
        )
    ]
)
