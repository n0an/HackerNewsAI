import Foundation

actor LastVisitService {
    private let key = "lastSummaryVisitTimestamp"
    private let defaults = UserDefaults.standard

    func getLastVisit() -> Date? {
        let timestamp = defaults.double(forKey: key)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    func updateLastVisit() {
        defaults.set(Date().timeIntervalSince1970, forKey: key)
    }

    func timeSinceLastVisit() -> TimeInterval? {
        guard let lastVisit = getLastVisit() else { return nil }
        return Date().timeIntervalSince(lastVisit)
    }

    func formattedTimeSinceLastVisit() -> String {
        guard let lastVisit = getLastVisit() else {
            return "your first visit"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastVisit, relativeTo: Date())
    }
}
