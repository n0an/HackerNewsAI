import Foundation

struct HNStory: Codable, Identifiable, Equatable {
    let id: Int
    let title: String
    let by: String
    let score: Int
    let time: Int
    let descendants: Int?
    let url: String?
    let text: String?
    let type: String

    var storyURL: URL? {
        guard let url else { return nil }
        return URL(string: url)
    }

    var domain: String? {
        guard let storyURL else { return nil }
        return storyURL.host?.replacingOccurrences(of: "www.", with: "")
    }

    var postedDate: Date {
        Date(timeIntervalSince1970: TimeInterval(time))
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: postedDate, relativeTo: Date())
    }

    var isFromToday: Bool {
        Calendar.current.isDateInToday(postedDate)
    }

    var commentCount: Int {
        descendants ?? 0
    }
}
