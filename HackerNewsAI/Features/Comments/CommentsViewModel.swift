import Foundation
import Observation

@Observable
class CommentsViewModel {
    let story: HNStory
    var commentNodes: [CommentNode] = []
    var collapsedIDs: Set<Int> = []
    var isLoading = false
    var error: Error?

    private let service = HackerNewsService()

    init(story: HNStory) {
        self.story = story
    }

    @MainActor
    func loadComments() async {
        guard !isLoading else { return }
        guard let commentIDs = story.kids, !commentIDs.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            commentNodes = try await service.fetchCommentTree(ids: commentIDs)
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
