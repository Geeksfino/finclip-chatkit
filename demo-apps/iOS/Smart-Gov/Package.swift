// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iLoveHK-App",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "iLoveHK-App",
            type: .dynamic,
            targets: ["iLoveHK-App"]
        )
    ],
    dependencies: [
        // ChatKit with remote binary XCFramework
        .package(
            url: "https://github.com/Geeksfino/finclip-chatkit.git",
            from: "0.2.1"
        )
    ],
    targets: [
        .target(
            name: "iLoveHK-App",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ],
            path: "App",
            sources: [
                "App",
                "Coordinators",
                "Models",
                "Network",
                "ViewControllers"
            ],
            resources: [
                .copy("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"])
            ]
        )
    ]
)
