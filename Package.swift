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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.9/FinClipChatKit.xcframework.zip",
            checksum: "5ca513fac5e059b6e61ca34d7044dfd27b571c348ca0f28aabad75aff19bb703"
        )
    ]
)
