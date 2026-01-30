import SwiftUI

struct SummaryView: View {
    @State private var viewModel = SummaryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if let summary = viewModel.summary {
                    summaryContent(summary)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Catch Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        Task {
                            await viewModel.markAsRead()
                        }
                        dismiss()
                    }
                }

                if viewModel.summary != nil && !viewModel.isLoading {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task {
                                await viewModel.regenerate()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            if viewModel.summary == nil {
                await viewModel.generateSummary()
            }
        }
    }

    private func summaryContent(_ summary: CatchUpSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Time context header
                if summary.isFirstVisit {
                    Label("Welcome!", systemImage: "hand.wave")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Last visited \(summary.timeSinceLastVisit)", systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Summary content
                Text(summary.summary)
                    .font(.body)

                Divider()

                // Footer info
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Based on \(summary.storyCount) top stories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Catching you up...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Analyzing recent stories")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func errorView(error: Error) -> some View {
        ContentUnavailableView {
            Label("Unable to Generate", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.generateSummary()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    SummaryView()
}
