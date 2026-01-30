import Foundation
import LLM

actor SummaryService {
    private let hnService: HackerNewsService
    private var cachedSummary: DailySummary?

    private let model = SystemLanguageModel.default

    init(hnService: HackerNewsService = HackerNewsService()) {
        self.hnService = hnService
    }

    func generateTodaySummary(forceRegenerate: Bool = false) async throws -> DailySummary {
        // Return cached summary if available and not forcing regeneration
        if !forceRegenerate, let cached = cachedSummary, cached.isFromToday {
            return cached
        }

        // Fetch today's top stories
        let stories = try await hnService.fetchTodaysTopStories(limit: 50)

        guard !stories.isEmpty else {
            throw SummaryError.noStoriesAvailable
        }

        // Build the prompt
        let prompt = buildPrompt(from: stories)

        // Generate summary using LLM
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)

        let summary = DailySummary(
            date: Date(),
            summary: response.content,
            storyCount: stories.count,
            generatedAt: Date()
        )

        // Cache the result
        cachedSummary = summary

        return summary
    }

    func getCachedSummary() -> DailySummary? {
        guard let cached = cachedSummary, cached.isFromToday else {
            return nil
        }
        return cached
    }

    func clearCache() {
        cachedSummary = nil
    }

    private func buildPrompt(from stories: [HNStory]) -> String {
        var prompt = """
        You are a tech news summarizer. Based on today's top Hacker News stories, provide a brief summary of the most important themes and news.

        Today's Top Stories (sorted by popularity):

        """

        for (index, story) in stories.enumerated() {
            let domain = story.domain ?? "self"
            prompt += "\(index + 1). [Score: \(story.score)] \"\(story.title)\" (\(domain))\n"
        }

        prompt += """

        Summarize the key themes and most significant news in 3-5 bullet points.
        Focus on: major announcements, trending technologies, notable launches, and interesting discussions.
        Be concise but informative. Use bullet points with brief explanations.
        """

        return prompt
    }
}

enum SummaryError: LocalizedError {
    case noStoriesAvailable

    var errorDescription: String? {
        switch self {
        case .noStoriesAvailable:
            return "No stories from today are available yet."
        }
    }
}
