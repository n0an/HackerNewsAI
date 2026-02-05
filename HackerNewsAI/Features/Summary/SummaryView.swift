import SwiftUI

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct SummaryView: View {
    @State private var viewModel = SummaryViewModel()
    @State private var markedAsRead = false
    @State private var selectedURL: URL?
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if let summary = viewModel.summary, !summary.isAllCaughtUp, !viewModel.isLoading {
                    ToolbarItem(placement: .primaryAction) {
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
        #if os(iOS)
        .fullScreenCover(item: $selectedURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        #else
        .sheet(item: $selectedURL) { url in
            SafariView(url: url)
                .frame(minWidth: 600, minHeight: 400)
        }
        #endif
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

            Text("You checked \(summary.timeSinceLastVisit).\n\nCheck back later for updates.")
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
                .foregroundStyle(Color.accentColor)
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
                    Text(markdownAttributedString(from: summaryText))
                        .font(.body)
                }

                // Stories section
                if !summary.stories.isEmpty {
                    Divider()

                    Text("Stories")
                        .font(.headline)
                        .padding(.top, 8)

                    ForEach(summary.stories.prefix(30)) { story in
                        Button {
                            if let url = story.storyURL {
                                selectedURL = url
                            }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "link")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(story.title)
                                        .font(.subheadline)
                                        .multilineTextAlignment(.leading)
                                        .foregroundStyle(.primary)

                                    HStack(spacing: 8) {
                                        if let domain = story.domain {
                                            Text(domain)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Text("\(story.score) points")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .disabled(story.storyURL == nil)
                    }
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
                    .foregroundStyle(markedAsRead ? Color.green : Color.accentColor)
                    .cornerRadius(12)
                }
                .disabled(markedAsRead)
            }
            .padding()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            if let progress = viewModel.downloadProgress, progress < 1.0 {
                // Model downloading - show progress
                VStack(spacing: 12) {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(width: 200)

                    Text("Downloading model...")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            } else {
                // Normal loading - generating summary
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

    private func markdownAttributedString(from text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}

#Preview {
    SummaryView()
}
