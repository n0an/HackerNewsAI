import Foundation

struct DailySummary {
    let date: Date
    let summary: String
    let storyCount: Int
    let generatedAt: Date

    var isFromToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
