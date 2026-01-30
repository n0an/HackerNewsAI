import Foundation

struct CatchUpSummary {
    let summary: String
    let storyCount: Int
    let lastVisit: Date?
    let timeSinceLastVisit: String
    let hasNewStories: Bool
    let generatedAt: Date

    var isFirstVisit: Bool {
        lastVisit == nil
    }
}
