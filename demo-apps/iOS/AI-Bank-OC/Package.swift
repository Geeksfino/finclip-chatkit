// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AI-Bank-OC",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.2.1")
    ],
    targets: [
        .target(
            name: "AI-Bank-OC",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)


