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
            .navigationTitle("Today's Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
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

    private func summaryContent(_ summary: DailySummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(summary.summary)
                    .font(.body)

                Divider()

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Generated from \(summary.storyCount) stories")
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
            Text("Analyzing today's news...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("This may take a moment")
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
