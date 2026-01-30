// LLMGenerationService - LLM Module
// Copyright 2026

import Foundation
import MLXLLM
import MLXLMCommon
import MLX

/// Errors that can occur during LLM generation
public enum LLMError: LocalizedError {
    case apiKeyMissing
    case foundationModelsUnavailable

    public var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Anthropic API key is not configured. Please add it in Settings."
        case .foundationModelsUnavailable:
            return "Foundation Models require macOS 26.0 or iOS 26.0."
        }
    }
}

/// Service for generating text using various LLM providers
public actor LLMGenerationService {
    /// Shared instance
    public static let shared = LLMGenerationService()

    // Cache for MLX model containers
    private var mlxModelCache: [String: ModelContainer] = [:]

    // Progress callback for model downloads
    private var onDownloadProgress: (@Sendable (Double) -> Void)?

    public init() {}

    /// Set callback for download progress updates
    public func setProgressCallback(_ callback: @escaping @Sendable (Double) -> Void) {
        onDownloadProgress = callback
    }

    /// Generate a response using the configured LLM
    public func generate(prompt: String, configuration: LLMConfiguration) async throws -> String {
        let rawResponse: String

        switch configuration.provider {
        case .onDevice:
            rawResponse = try await generateWithFoundationModel(prompt: prompt)
        case .mlx:
            rawResponse = try await generateWithMLX(prompt: prompt, modelId: configuration.mlxModelId)
        case .anthropic:
            rawResponse = try await generateWithAnthropic(prompt: prompt, apiKey: configuration.anthropicAPIKey)
        }

        return LLMResponseFilter.filter(rawResponse)
    }

    // MARK: - Foundation Models

    private func generateWithFoundationModel(prompt: String) async throws -> String {
        if #available(macOS 26.0, iOS 26.0, *) {
            let session = LanguageModelSession(model: SystemLanguageModel.default)
            let response = try await session.respond(to: prompt)
            return response.content
        } else {
            throw LLMError.foundationModelsUnavailable
        }
    }

    // MARK: - Anthropic

    private func generateWithAnthropic(prompt: String, apiKey: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw LLMError.apiKeyMissing
        }
        let model = AnthropicLanguageModel(
            apiKey: apiKey,
            model: "claude-sonnet-4-5-20250929"
        )
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    // MARK: - MLX

    private func generateWithMLX(prompt: String, modelId: String) async throws -> String {
        let container = try await loadMLXModel(modelId: modelId)

        var responseText = ""

        // Create input inside perform to avoid Sendable issues
        let stream = try await container.perform { (context: ModelContext) in
            let userInput = UserInput(
                chat: [Chat.Message(role: .user, content: prompt)]
            )
            let input = try await context.processor.prepare(input: userInput)
            let parameters = GenerateParameters(temperature: 0.7)
            return try MLXLMCommon.generate(input: input, parameters: parameters, context: context)
        }

        for await generation in stream {
            switch generation {
            case .chunk(let chunk):
                responseText += chunk
            case .info:
                break
            case .toolCall:
                break
            }
        }

        return responseText
    }

    private func loadMLXModel(modelId: String) async throws -> ModelContainer {
        if let cached = mlxModelCache[modelId] {
            print("[MLX] Using cached model: \(modelId)")
            return cached
        }

        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        print("[MLX] Cache directory: \(cacheDir?.path ?? "unknown")")
        print("[MLX] HuggingFace models typically stored in: ~/.cache/huggingface/hub/")
        print("[MLX] Loading model: \(modelId)")

        Memory.cacheLimit = 20 * 1024 * 1024

        let configuration = getModelConfiguration(for: modelId)
        print("[MLX] Using configuration: \(configuration)")

        let progressCallback = onDownloadProgress

        let container = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progress in
            progressCallback?(progress.fractionCompleted)
        }

        progressCallback?(1.0)

        mlxModelCache[modelId] = container

        return container
    }

    private func getModelConfiguration(for modelId: String) -> ModelConfiguration {
        switch modelId {
        case "mlx-community/Qwen3-0.6B-4bit":
            return LLMRegistry.qwen3_0_6b_4bit
        case "mlx-community/Qwen3-4B-4bit":
            return LLMRegistry.qwen3_4b_4bit
        case "mlx-community/Llama-3.2-3B-Instruct-4bit":
            return LLMRegistry.llama3_2_3B_4bit
        default:
            return LLMRegistry.qwen3_0_6b_4bit
        }
    }
}
