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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.11/FinClipChatKit.xcframework.zip",
            checksum: "df4441721e5d1e6ebbb6ca8c515ad20f396a3d546d724b93b49ded5a93df15b3"
        )
    ]
)
