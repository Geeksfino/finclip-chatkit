// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ChatKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "ChatKit", targets: ["ChatKit"]),
        .library(name: "ConvoUI", targets: ["ConvoUI"]),
        .library(name: "NeuronKit", targets: ["NeuronKit"]),
        .library(name: "SandboxSDK", targets: ["SandboxSDK"]),
        .library(name: "convstorelib", targets: ["convstorelib"])
    ],
    targets: [
        .binaryTarget(
            name: "ChatKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip",
            checksum: "365a1bc10574cd4000e52f3cde78a745a3a60ebcde10c81e59c5b5d8390602b4"
        ),
        .binaryTarget(
            name: "ConvoUI",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ConvoUI.xcframework.zip",
            checksum: "8c62bc1a85df41dc7c20e6c84f30fc21e67eda95e7c93928 6bf1dcf82aa61c8c"
        ),
        .binaryTarget(
            name: "NeuronKit",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/NeuronKit.xcframework.zip",
            checksum: "d49e1f764433743df6141684416880e13747acb3bf51743106282b25ce6b238f"
        ),
        .binaryTarget(
            name: "SandboxSDK",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/SandboxSDK.xcframework.zip",
            checksum: "23f3752661400d33602e5869977a5ba8ed9e63543058f879fe2ad12e5a180e58"
        ),
        .binaryTarget(
            name: "convstorelib",
            url: "https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/convstorelib.xcframework.zip",
            checksum: "796d157a1408900d620f625ebe1ce9d64b53997d1ce9fc1a7617ecf348693e76"
        )
    ]
)
