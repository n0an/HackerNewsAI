// SummaryService - HackerNewsAI
// Copyright 2026

import Foundation
import LLM
import MLX
import MLXLLM
import MLXLMCommon

actor SummaryService {
    private let hnService: HackerNewsService
    private let lastVisitService: LastVisitService
    private var cachedSummary: CatchUpSummary?

    // Minimum time before generating a new summary (30 minutes)
    private let minimumTimeBetweenSummaries: TimeInterval = 30 * 60

    // Cache for MLX model containers
    private var mlxModelCache: [String: ModelContainer] = [:]

    // Progress callback for model downloads
    private var onDownloadProgress: (@Sendable (Double) -> Void)?

    func setProgressCallback(_ callback: @escaping @Sendable (Double) -> Void) {
        onDownloadProgress = callback
    }

    init(
        hnService: HackerNewsService = HackerNewsService(),
        lastVisitService: LastVisitService = LastVisitService()
    ) {
        self.hnService = hnService
        self.lastVisitService = lastVisitService
    }

    func generateCatchUpSummary(forceRegenerate: Bool = false, bypassTimeCheck: Bool = false) async throws -> CatchUpSummary {
        // Return cached summary if available and recent (within 5 minutes)
        if !forceRegenerate, let cached = cachedSummary,
           Date().timeIntervalSince(cached.generatedAt) < 300 {
            return cached
        }

        let lastVisit = await lastVisitService.getLastVisit()
        let timeSinceDescription = await lastVisitService.formattedTimeSinceLastVisit()

        // Check if user visited recently - if so, they're "all caught up"
        if !bypassTimeCheck, let lastVisit = lastVisit {
            let timeSinceLastVisit = Date().timeIntervalSince(lastVisit)

            if timeSinceLastVisit < minimumTimeBetweenSummaries {
                let summary = CatchUpSummary.allCaughtUp(
                    lastVisit: lastVisit,
                    timeSince: timeSinceDescription
                )
                cachedSummary = summary
                return summary
            }
        }

        // Fetch stories since last visit
        let stories = try await hnService.fetchStoriesSince(lastVisit, limit: 50)

        guard !stories.isEmpty else {
            throw SummaryError.noStoriesAvailable
        }

        // Determine if these are new stories or just current top
        let hasNewStories = lastVisit == nil || stories.contains { $0.postedDate > lastVisit! }

        // Build the prompt
        let prompt = buildPrompt(from: stories, lastVisit: lastVisit, timeSinceDescription: timeSinceDescription, hasNewStories: hasNewStories)

        // Generate summary using the configured LLM
        let responseText = try await generateResponse(prompt: prompt)

        let summary = CatchUpSummary(
            summary: responseText,
            storyCount: stories.count,
            lastVisit: lastVisit,
            timeSinceLastVisit: timeSinceDescription,
            hasNewStories: hasNewStories,
            isAllCaughtUp: false,
            generatedAt: Date()
        )

        cachedSummary = summary
        return summary
    }

    private func generateResponse(prompt: String) async throws -> String {
        let settings = SettingsService.shared

        let rawResponse: String
        switch settings.provider {
        case .onDevice:
            rawResponse = try await generateWithFoundationModel(prompt: prompt)
        case .mlx:
            rawResponse = try await generateWithMLX(prompt: prompt, modelId: settings.mlxModelId)
        case .anthropic:
            rawResponse = try await generateWithAnthropic(prompt: prompt)
        }

        return stripThinkingTags(from: rawResponse)
    }

    private func stripThinkingTags(from text: String) -> String {
        var processedText = text

        // Step 1: Remove thinking/reasoning tags WITH their content (discard AI's chain-of-thought)
        let thinkingPatterns = [
            #"(?s)<thinking>(.*?)</thinking>"#,
            #"(?s)<think>(.*?)</think>"#,
            #"(?s)<reasoning>(.*?)</reasoning>"#
        ]

        for pattern in thinkingPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(processedText.startIndex..., in: processedText)
                processedText = regex.stringByReplacingMatches(in: processedText, options: [], range: range, withTemplate: "")
            }
        }

        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Step 2: Unwrap any XML tags that wrap the entire text (keep content, remove wrapper)
        processedText = unwrapOuterXMLTags(processedText)

        return processedText
    }

    private func unwrapOuterXMLTags(_ text: String) -> String {
        // Match pattern like <TAG>content</TAG> where TAG wraps the entire text
        let pattern = #"^<([A-Za-z_][A-Za-z0-9_]*)>\s*([\s\S]*?)\s*</\1>$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let contentRange = Range(match.range(at: 2), in: text) else {
            return text
        }
        return String(text[contentRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateWithFoundationModel(prompt: String) async throws -> String {
        let session = LanguageModelSession(model: SystemLanguageModel.default)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    private func generateWithAnthropic(prompt: String) async throws -> String {
        let settings = SettingsService.shared
        guard settings.isAnthropicConfigured else {
            throw SummaryError.apiKeyMissing
        }
        let model = AnthropicLanguageModel(
            apiKey: settings.anthropicAPIKey,
            model: "claude-sonnet-4-5-20250929"
        )
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)
        return response.content
    }

    private func generateWithMLX(prompt: String, modelId: String) async throws -> String {
        // Load or get cached model
        let container = try await loadMLXModel(modelId: modelId)

        // Create user input with the prompt
        let userInput = UserInput(
            chat: [Chat.Message(role: .user, content: prompt)]
        )

        // Generate response
        var responseText = ""

        let stream = try await container.perform { (context: ModelContext) in
            let input = try await context.processor.prepare(input: userInput)
            let parameters = GenerateParameters(temperature: 0.7)
            return try MLXLMCommon.generate(input: input, parameters: parameters, context: context)
        }

        // Collect the streamed response - Generation is an enum
        for await generation in stream {
            switch generation {
            case .chunk(let chunk):
                responseText += chunk
            case .info:
                break // Performance info, ignore for now
            case .toolCall:
                break // Tool calls, not used
            }
        }

        return responseText
    }

    private func loadMLXModel(modelId: String) async throws -> ModelContainer {
        // Check cache first
        if let cached = mlxModelCache[modelId] {
            print("[MLX] Using cached model: \(modelId)")
            return cached
        }

        // Debug: Print cache directory location
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        print("[MLX] Cache directory: \(cacheDir?.path ?? "unknown")")
        print("[MLX] HuggingFace models typically stored in: ~/.cache/huggingface/hub/")
        print("[MLX] Loading model: \(modelId)")

        // Set memory limit for GPU
        Memory.cacheLimit = 20 * 1024 * 1024

        // Get the model configuration from registry based on modelId
        let configuration = getModelConfiguration(for: modelId)
        print("[MLX] Using configuration: \(configuration)")

        // Capture callback for use in closure
        let progressCallback = onDownloadProgress

        // Load the model with progress tracking
        let container = try await LLMModelFactory.shared.loadContainer(
            configuration: configuration
        ) { progress in
            progressCallback?(progress.fractionCompleted)
        }

        // Signal download complete
        progressCallback?(1.0)

        // Cache it
        mlxModelCache[modelId] = container

        return container
    }

    private func getModelConfiguration(for modelId: String) -> ModelConfiguration {
        // Map our model IDs to LLMRegistry configurations
        switch modelId {
        case "mlx-community/Qwen3-0.6B-4bit":
            return LLMRegistry.qwen3_0_6b_4bit
        case "mlx-community/Qwen3-4B-4bit":
            return LLMRegistry.qwen3_4b_4bit
        case "mlx-community/Llama-3.2-3B-Instruct-4bit":
            return LLMRegistry.llama3_2_3B_4bit
        default:
            // Default to Qwen3 0.6B for unknown models
            return LLMRegistry.qwen3_0_6b_4bit
        }
    }

    func markAsRead() async {
        await lastVisitService.updateLastVisit()
        cachedSummary = nil
    }

    func clearCache() {
        cachedSummary = nil
    }

    private func buildPrompt(from stories: [HNStory], lastVisit: Date?, timeSinceDescription: String, hasNewStories: Bool) -> String {
        let contextIntro: String
        if lastVisit == nil {
            contextIntro = "This is the user's first time using the app. Give them a warm welcome and summarize what's currently trending on Hacker News."
        } else if hasNewStories {
            contextIntro = "The user last checked Hacker News \(timeSinceDescription). Summarize what they missed."
        } else {
            contextIntro = "The user last checked Hacker News \(timeSinceDescription). There are no major new stories since then, but here's what's currently trending. Let them know nothing big happened but share what's popular right now."
        }

        var prompt = """
        You are a helpful tech news assistant. \(contextIntro)

        Current top Hacker News stories:

        """

        for (index, story) in stories.prefix(30).enumerated() {
            let domain = story.domain ?? "self"
            let timeAgo = story.relativeTime
            prompt += "\(index + 1). [Score: \(story.score), \(timeAgo)] \"\(story.title)\" (\(domain))\n"
        }

        prompt += """

        Provide a concise catch-up summary:
        - Start with a brief greeting acknowledging the time away (e.g., "Since you've been away..." or "Welcome! Here's what's trending...")
        - List the 3-5 most important/interesting things happening
        - Use bullet points with brief explanations
        - Focus on: major announcements, trending discussions, notable launches
        - Keep it conversational and scannable
        """

        return prompt
    }
}

enum SummaryError: LocalizedError {
    case noStoriesAvailable
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .noStoriesAvailable:
            return "No stories available at the moment."
        case .apiKeyMissing:
            return "Anthropic API key is not configured. Please add it in Settings."
        }
    }
}
