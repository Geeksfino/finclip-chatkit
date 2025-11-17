// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GemmaTest",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.13.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "GemmaTest",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXFast", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GemmaTest"
        )
    ]
)

