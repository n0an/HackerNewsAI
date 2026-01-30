// LLMConfiguration - LLM Module
// Copyright 2026

import Foundation

/// Configuration for LLM generation
public struct LLMConfiguration: Sendable {
    public let provider: LLMProvider
    public let anthropicAPIKey: String
    public let mlxModelId: String

    public init(provider: LLMProvider, anthropicAPIKey: String = "", mlxModelId: String = "mlx-community/Qwen3-0.6B-4bit") {
        self.provider = provider
        self.anthropicAPIKey = anthropicAPIKey
        self.mlxModelId = mlxModelId
    }

    public var isAnthropicConfigured: Bool {
        !anthropicAPIKey.isEmpty
    }
}
