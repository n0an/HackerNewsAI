import Foundation
import Observation

@Observable
class SummaryViewModel {
    var summary: CatchUpSummary?
    var isLoading = false
    var error: Error?

    private let service = SummaryService()

    @MainActor
    func generateSummary(forceRegenerate: Bool = false) async {
        isLoading = true
        error = nil

        do {
            summary = try await service.generateCatchUpSummary(forceRegenerate: forceRegenerate)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func regenerate() async {
        await generateSummary(forceRegenerate: true)
    }

    @MainActor
    func markAsRead() async {
        await service.markAsRead()
    }
}
