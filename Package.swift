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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.14/FinClipChatKit.xcframework.zip",
            checksum: "512545168c7bc1c6d6de9ed6bc565f10247820cf58da655769ba432b14e8858b"
        )
    ]
)
