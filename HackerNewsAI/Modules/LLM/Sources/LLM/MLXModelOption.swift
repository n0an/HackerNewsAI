// MLXModelOption - LLM Module
// Copyright 2026

import Foundation

public struct MLXModelOption: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let size: String
    public let description: String

    public init(id: String, displayName: String, size: String, description: String) {
        self.id = id
        self.displayName = displayName
        self.size = size
        self.description = description
    }

    public static let available: [MLXModelOption] = [
        MLXModelOption(
            id: "mlx-community/Qwen3-0.6B-4bit",
            displayName: "Qwen3 0.6B",
            size: "~400MB",
            description: "Fastest, minimal memory"
        ),
        MLXModelOption(
            id: "mlx-community/Qwen3-4B-4bit",
            displayName: "Qwen3 4B",
            size: "~2.5GB",
            description: "Best balance of speed and quality"
        ),
        MLXModelOption(
            id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            displayName: "Llama 3.2 3B",
            size: "~2GB",
            description: "Good quality, moderate size"
        ),
    ]
}
