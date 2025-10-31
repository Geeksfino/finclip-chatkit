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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip",
            checksum: "365a1bc10574cd4000e52f3cde78a745a3a60ebcde10c81e59c5b5d8390602b4"
        )
    ]
)
