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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.4.0/ChatKit.xcframework.zip",
            checksum: "59c43387c276e35c7536125cc6ab0c34314d2f2ea93a7624e88ff48c7761540a"
        )
    ]
)
