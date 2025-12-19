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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.13/FinClipChatKit.xcframework.zip",
            checksum: "373665b7460689d61cd6e20a13756ff6733eb8816759228c77e3a23cfae4ad6b"
        )
    ]
)
