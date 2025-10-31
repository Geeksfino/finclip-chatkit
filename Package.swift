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
            targets: ["ChatKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "ChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip",
            checksum: "8a8aa4f56d47587001700fb996f48c4528c26632115813ea68a25445bb2900fb"
        )
    ]
)
