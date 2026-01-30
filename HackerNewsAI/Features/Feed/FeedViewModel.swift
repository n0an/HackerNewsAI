import Foundation
import Observation

@Observable
class FeedViewModel {
    var stories: [HNStory] = []
    var isLoading = false
    var isLoadingMore = false
    var error: Error?

    private let service = HackerNewsService()
    private var allStoryIDs: [Int] = []
    private var loadedCount = 0
    private let pageSize = 30

    @MainActor
    func loadTopStories() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            allStoryIDs = try await service.fetchTopStoryIDs()
            loadedCount = 0
            stories = try await service.fetchStories(ids: allStoryIDs, limit: pageSize)
            loadedCount = pageSize
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func loadMore() async {
        guard !isLoadingMore, !isLoading, loadedCount < allStoryIDs.count else { return }

        isLoadingMore = true

        do {
            let nextIDs = Array(allStoryIDs.dropFirst(loadedCount).prefix(pageSize))
            let moreStories = try await service.fetchStories(ids: nextIDs, limit: pageSize)
            stories.append(contentsOf: moreStories)
            loadedCount += pageSize
        } catch {
            self.error = error
        }

        isLoadingMore = false
    }

    @MainActor
    func refresh() async {
        allStoryIDs = []
        loadedCount = 0
        await loadTopStories()
    }

    var hasMoreStories: Bool {
        loadedCount < allStoryIDs.count
    }
}
