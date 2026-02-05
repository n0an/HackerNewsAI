import Foundation

struct CatchUpSummary {
    let summary: String?
    let storyCount: Int
    let lastVisit: Date?
    let timeSinceLastVisit: String
    let hasNewStories: Bool
    let isAllCaughtUp: Bool
    let generatedAt: Date
    let stories: [HNStory]

    var isFirstVisit: Bool {
        lastVisit == nil
    }

    static func allCaughtUp(lastVisit: Date?, timeSince: String) -> CatchUpSummary {
        CatchUpSummary(
            summary: nil,
            storyCount: 0,
            lastVisit: lastVisit,
            timeSinceLastVisit: timeSince,
            hasNewStories: false,
            isAllCaughtUp: true,
            generatedAt: Date(),
            stories: []
        )
    }
}
