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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.0.2/ChatKit.xcframework.zip",
            checksum: "35297ee426b499ea736df7b5c30489b6515cfcb32548ab2927438ce7f4453f44"
        )
    ]
)
