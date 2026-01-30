import Foundation

struct HNComment: Codable, Identifiable {
    let id: Int
    let by: String?
    let text: String?
    let time: Int
    let parent: Int
    let kids: [Int]?
    let type: String

    var author: String {
        by ?? "[deleted]"
    }

    var content: String {
        text ?? "[deleted]"
    }

    var postedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: postedDate, relativeTo: Date())
    }

    var childCount: Int {
        kids?.count ?? 0
    }
}
