// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GemmaTestAppFeature",
    platforms: [.macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GemmaTestAppFeature",
            targets: ["GemmaTestAppFeature"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.13.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.13"),
        .package(url: "https://github.com/jkrukowski/swift-sentencepiece", from: "0.0.3")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GemmaTestAppFeature",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXFast", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Transformers", package: "swift-transformers"),
                .product(name: "SentencepieceTokenizer", package: "swift-sentencepiece")
            ]
        ),
        .testTarget(
            name: "GemmaTestAppFeatureTests",
            dependencies: [
                "GemmaTestAppFeature"
            ]
        ),
    ]
)
