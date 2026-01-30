import Foundation
import Observation

@Observable
class SummaryViewModel {
    var summary: DailySummary?
    var isLoading = false
    var error: Error?

    private let service = SummaryService()

    @MainActor
    func generateSummary(forceRegenerate: Bool = false) async {
        isLoading = true
        error = nil

        do {
            summary = try await service.generateTodaySummary(forceRegenerate: forceRegenerate)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func regenerate() async {
        await generateSummary(forceRegenerate: true)
    }

    var hasCachedSummary: Bool {
        summary != nil
    }
}
