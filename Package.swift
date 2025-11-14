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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.7.1/FinClipChatKit.xcframework.zip",
            checksum: "a977217dbeabb6700e751e9d0919566d26a9b3f814a530f95109907bfa5f7486"
        )
    ]
)
