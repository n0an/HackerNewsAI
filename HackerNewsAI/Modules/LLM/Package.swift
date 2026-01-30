// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LLM",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(
            name: "LLM",
            targets: ["LLM"]
        ),
    ],
    dependencies: [
        // AnyLanguageModel for Foundation Models + Anthropic (no MLX trait needed)
        .package(
            url: "https://github.com/mattt/AnyLanguageModel",
            branch: "main"
        ),
        // MLX directly from mlx-swift-lm
        .package(
            url: "https://github.com/ml-explore/mlx-swift-lm",
            from: "2.30.0"
        )
    ],
    targets: [
        .target(
            name: "LLM",
            dependencies: [
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
                // MLX works on both macOS and iOS with Apple Silicon
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
            ]
        ),
        .testTarget(
            name: "LLMTests",
            dependencies: ["LLM"]
        ),
    ]
)
