// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MyPal",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/Geeksfino/finclip-chatkit.git", from: "0.7.2")
    ],
    targets: [
        .target(
            name: "MyPal",
            dependencies: [
                .product(name: "FinClipChatKit", package: "finclip-chatkit")
            ]
        )
    ]
)

