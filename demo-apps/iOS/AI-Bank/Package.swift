// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AI-Bank",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "AI-Bank",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit"),
                .product(name: "ConvoUI", package: "finclip-chatkit"),
                .product(name: "NeuronKit", package: "finclip-chatkit"),
                .product(name: "SandboxSDK", package: "finclip-chatkit"),
                .product(name: "convstorelib", package: "finclip-chatkit")
            ]
        )
    ]
)
