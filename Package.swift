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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.6.0/ChatKit.xcframework.zip",
            checksum: "06ed36bba0dcf270bd3c1e9c5c0ad69ae236eed1836da371ad7c6288f77b5a32"
        )
    ]
)
