import Foundation

actor HackerNewsService {
    private let baseURL = "https://hacker-news.firebaseio.com/v0"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTopStoryIDs() async throws -> [Int] {
        let url = URL(string: "\(baseURL)/topstories.json")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Int].self, from: data)
    }

    func fetchNewStoryIDs() async throws -> [Int] {
        let url = URL(string: "\(baseURL)/newstories.json")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([Int].self, from: data)
    }

    func fetchStory(id: Int) async throws -> HNStory? {
        let url = URL(string: "\(baseURL)/item/\(id).json")!
        let (data, _) = try await session.data(from: url)

        guard let story = try? JSONDecoder().decode(HNStory.self, from: data) else {
            return nil
        }

        // Filter: only return stories (not jobs, polls, etc.)
        guard story.type == "story" else { return nil }

        return story
    }

    func fetchStories(ids: [Int], limit: Int = 30) async throws -> [HNStory] {
        let idsToFetch = Array(ids.prefix(limit))

        return try await withThrowingTaskGroup(of: HNStory?.self) { group in
            for id in idsToFetch {
                group.addTask {
                    try await self.fetchStory(id: id)
                }
            }

            var stories: [HNStory] = []
            for try await story in group {
                if let story {
                    stories.append(story)
                }
            }

            // Sort by score descending to maintain relevance order
            return stories.sorted { $0.score > $1.score }
        }
    }

    func fetchTodaysTopStories(limit: Int = 50) async throws -> [HNStory] {
        let ids = try await fetchTopStoryIDs()
        let stories = try await fetchStories(ids: ids, limit: min(limit * 2, 100))

        // Filter to today's stories only
        let todaysStories = stories.filter { $0.isFromToday }

        return Array(todaysStories.prefix(limit))
    }
}
