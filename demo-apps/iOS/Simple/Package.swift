// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Simple",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "Simple",
            dependencies: [
                .product(name: "FinClipChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)

