// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// MLX is Apple Silicon only
#if os(Linux)
let anyLanguageModelTraits: Set<Package.Dependency.Trait> = []
#else
let anyLanguageModelTraits: Set<Package.Dependency.Trait> = ["MLX"]
#endif

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
        .package(
            url: "https://github.com/mattt/AnyLanguageModel",
            branch: "main",
            traits: anyLanguageModelTraits
        )
    ],
    targets: [
        .target(
            name: "LLM",
            dependencies: [
                .product(name: "AnyLanguageModel", package: "AnyLanguageModel"),
            ]
        ),
        .testTarget(
            name: "LLMTests",
            dependencies: ["LLM"]
        ),
    ]
)
