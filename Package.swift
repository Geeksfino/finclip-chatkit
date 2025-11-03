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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.2.1/ChatKit.xcframework.zip",
            checksum: "4c05da179daf5283b16f4b5617ee4f349d41d83b357938fa9373bf754c883782"
        )
    ]
)
