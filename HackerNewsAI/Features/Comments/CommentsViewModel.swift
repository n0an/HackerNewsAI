// CommentsViewModel - HackerNewsAI
// Copyright 2026

import Foundation

@Observable
@MainActor
class CommentsViewModel {
    let story: HNStory
    var commentNodes: [CommentNode] = []
    var collapsedIDs: Set<Int> = []
    var isLoading = false
    var isLoadingMore = false
    var error: Error?

    // Pagination
    private var allCommentIDs: [Int] = []
    private var loadedCount = 0
    private let pageSize = 15

    var hasMoreComments: Bool {
        loadedCount < allCommentIDs.count
    }

    var remainingCount: Int {
        max(0, allCommentIDs.count - loadedCount)
    }

    private let service = HackerNewsService()

    init(story: HNStory) {
        self.story = story
        self.allCommentIDs = story.kids ?? []
    }

    func loadComments() async {
        guard !isLoading else { return }
        guard !allCommentIDs.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            let idsToLoad = Array(allCommentIDs.prefix(pageSize))
            commentNodes = try await service.fetchCommentTree(ids: idsToLoad)
            loadedCount = idsToLoad.count
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadMoreComments() async {
        guard !isLoadingMore, hasMoreComments else { return }

        isLoadingMore = true

        do {
            let startIndex = loadedCount
            let endIndex = min(startIndex + pageSize, allCommentIDs.count)
            let idsToLoad = Array(allCommentIDs[startIndex..<endIndex])

            let newNodes = try await service.fetchCommentTree(ids: idsToLoad)
            commentNodes.append(contentsOf: newNodes)
            loadedCount = endIndex
        } catch {
            self.error = error
        }

        isLoadingMore = false
    }
}
