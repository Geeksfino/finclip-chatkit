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
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.9.6/FinClipChatKit.xcframework.zip",
            checksum: "9622322c58d850a063ff34d7e7423ce3cea92e666053ec7437de0a301876fc33"
        )
    ]
)
