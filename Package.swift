// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FinClipChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "FinClipChatKit", targets: ["FinClipChatKit"])
    ],
    targets: [
        .binaryTarget(
            name: "FinClipChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.1/FinClipChatKit.xcframework.zip",
            checksum: "b27da35c0da0b0c330c502f2f37b6bbbd9b3c7918c8332a5859c1e6fea40da99"
        )
    ]
)
