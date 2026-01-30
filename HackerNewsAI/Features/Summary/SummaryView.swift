import SwiftUI

struct SummaryView: View {
    @State private var viewModel = SummaryViewModel()
    @State private var markedAsRead = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.error {
                    errorView(error: error)
                } else if let summary = viewModel.summary {
                    if summary.isAllCaughtUp {
                        allCaughtUpView(summary)
                    } else {
                        summaryContent(summary)
                    }
                } else {
                    loadingView
                }
            }
            .navigationTitle("Catch Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if let summary = viewModel.summary, !summary.isAllCaughtUp, !viewModel.isLoading {
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

    private func allCaughtUpView(_ summary: CatchUpSummary) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You're all caught up!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No significant new stories since your last visit \(summary.timeSinceLastVisit).\n\nCheck back later for updates.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await viewModel.forceGenerateSummary()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Generate Summary Anyway")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(.accentColor)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            Spacer()
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
                if let summaryText = summary.summary {
                    Text(summaryText)
                        .font(.body)
                }

                Divider()

                // Footer info
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Based on \(summary.storyCount) top stories")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 20)

                // Mark as Read button
                Button {
                    Task {
                        await viewModel.markAsRead()
                        markedAsRead = true
                    }
                } label: {
                    HStack {
                        Image(systemName: markedAsRead ? "checkmark.circle.fill" : "checkmark.circle")
                        Text(markedAsRead ? "Marked as Read" : "Mark as Read")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(markedAsRead ? Color.green.opacity(0.2) : Color.accentColor.opacity(0.1))
                    .foregroundStyle(markedAsRead ? .green : .accentColor)
                    .cornerRadius(12)
                }
                .disabled(markedAsRead)
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
