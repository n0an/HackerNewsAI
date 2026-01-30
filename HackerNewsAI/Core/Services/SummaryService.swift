import Foundation
import LLM

actor SummaryService {
    private let hnService: HackerNewsService
    private let lastVisitService: LastVisitService
    private var cachedSummary: CatchUpSummary?

    // Minimum time before generating a new summary (30 minutes)
    private let minimumTimeBetweenSummaries: TimeInterval = 30 * 60

    private let model = SystemLanguageModel.default

    init(
        hnService: HackerNewsService = HackerNewsService(),
        lastVisitService: LastVisitService = LastVisitService()
    ) {
        self.hnService = hnService
        self.lastVisitService = lastVisitService
    }

    func generateCatchUpSummary(forceRegenerate: Bool = false) async throws -> CatchUpSummary {
        // Return cached summary if available and recent (within 5 minutes)
        if !forceRegenerate, let cached = cachedSummary,
           Date().timeIntervalSince(cached.generatedAt) < 300 {
            return cached
        }

        let lastVisit = await lastVisitService.getLastVisit()
        let timeSinceDescription = await lastVisitService.formattedTimeSinceLastVisit()

        // Check if user visited recently - if so, they're "all caught up"
        if let lastVisit = lastVisit {
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
        let prompt = buildPrompt(from: stories, lastVisit: lastVisit, timeSinceDescription: timeSinceDescription)

        // Generate summary using LLM
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(to: prompt)

        let summary = CatchUpSummary(
            summary: response.content,
            storyCount: stories.count,
            lastVisit: lastVisit,
            timeSinceLastVisit: timeSinceDescription,
            hasNewStories: hasNewStories,
            isAllCaughtUp: false,
            generatedAt: Date()
        )

        // Cache the result
        cachedSummary = summary

        return summary
    }

    func markAsRead() async {
        await lastVisitService.updateLastVisit()
        cachedSummary = nil
    }

    func clearCache() {
        cachedSummary = nil
    }

    private func buildPrompt(from stories: [HNStory], lastVisit: Date?, timeSinceDescription: String) -> String {
        let contextIntro: String
        if lastVisit == nil {
            contextIntro = "This is the user's first time using the app. Give them a warm welcome and summarize what's currently trending on Hacker News."
        } else {
            contextIntro = "The user last checked Hacker News \(timeSinceDescription). Summarize what they missed."
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

    var errorDescription: String? {
        switch self {
        case .noStoriesAvailable:
            return "No stories available at the moment."
        }
    }
}
