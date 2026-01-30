// SummaryViewModel - HackerNewsAI
// Copyright 2026

import Foundation

@Observable
@MainActor
class SummaryViewModel {
    var summary: CatchUpSummary?
    var isLoading = false
    var error: Error?

    // Download progress (0.0 to 1.0), nil when not downloading
    var downloadProgress: Double?
    var isDownloadingModel: Bool { downloadProgress != nil && downloadProgress! < 1.0 }

    private let service = SummaryService()

    init() {
        setupProgressTracking()
    }

    private func setupProgressTracking() {
        Task {
            await service.setProgressCallback { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
        }
    }

    func generateSummary(forceRegenerate: Bool = false) async {
        isLoading = true
        error = nil
        downloadProgress = nil

        do {
            summary = try await service.generateCatchUpSummary(forceRegenerate: forceRegenerate)
        } catch {
            self.error = error
        }

        isLoading = false
        downloadProgress = nil
    }

    func regenerate() async {
        await generateSummary(forceRegenerate: true)
    }

    func forceGenerateSummary() async {
        isLoading = true
        error = nil
        downloadProgress = nil

        do {
            summary = try await service.generateCatchUpSummary(forceRegenerate: true, bypassTimeCheck: true)
        } catch {
            self.error = error
        }

        isLoading = false
        downloadProgress = nil
    }

    func markAsRead() async {
        await service.markAsRead()
    }
}
