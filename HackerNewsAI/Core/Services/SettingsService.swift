// SettingsService - HackerNewsAI
// Copyright 2026

import Foundation
import LLM

@Observable
class SettingsService {
    static let shared = SettingsService()

    private let providerKey = "llm_provider"
    private let apiKeyKey = "anthropic_api_key"
    private let mlxModelKey = "mlx_model_id"
    private let defaults = UserDefaults.standard

    var provider: LLMProvider {
        didSet {
            defaults.set(provider.rawValue, forKey: providerKey)
        }
    }

    var anthropicAPIKey: String {
        didSet {
            defaults.set(anthropicAPIKey, forKey: apiKeyKey)
        }
    }

    var mlxModelId: String {
        didSet {
            defaults.set(mlxModelId, forKey: mlxModelKey)
        }
    }

    var isAnthropicConfigured: Bool {
        !anthropicAPIKey.isEmpty
    }

    var selectedMLXModel: MLXModelOption? {
        MLXModelOption.available.first { $0.id == mlxModelId }
    }

    /// Get current LLM configuration
    var llmConfiguration: LLMConfiguration {
        LLMConfiguration(
            provider: provider,
            anthropicAPIKey: anthropicAPIKey,
            mlxModelId: mlxModelId
        )
    }

    private init() {
        let savedProvider = defaults.string(forKey: providerKey) ?? LLMProvider.onDevice.rawValue
        self.provider = LLMProvider(rawValue: savedProvider) ?? .onDevice
        self.anthropicAPIKey = defaults.string(forKey: apiKeyKey) ?? ""
        self.mlxModelId = defaults.string(forKey: mlxModelKey) ?? "mlx-community/Qwen3-0.6B-4bit"
    }
}
