import SwiftUI
import WebKit

struct CommentsView: View {
    @State private var viewModel: CommentsViewModel
    @State private var showBrowser = false

    init(story: HNStory) {
        _viewModel = State(initialValue: CommentsViewModel(story: story))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Story header section
                StoryHeaderView(story: viewModel.story)
                    .padding()

                Divider()

                // Comments section
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let error = viewModel.error {
                    Text("Failed to load comments: \(error.localizedDescription)")
                        .foregroundStyle(.secondary)
                        .padding()
                } else if viewModel.commentNodes.isEmpty {
                    Text("No comments yet")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    commentsHeader
                        .padding(.horizontal)
                        .padding(.top)

                    ForEach(viewModel.commentNodes) { node in
                        CommentRowView(node: node, collapsedIDs: $viewModel.collapsedIDs)
                            .padding(.horizontal)
                    }

                    // Load More button
                    if viewModel.hasMoreComments {
                        loadMoreButton
                            .padding()
                    }
                }
            }
        }
        .navigationTitle("Comments")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .bottomBar) {
                if viewModel.story.storyURL != nil {
                    Button {
                        showBrowser = true
                    } label: {
                        Label("Read Article", systemImage: "doc.text")
                    }
                }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                if viewModel.story.storyURL != nil {
                    Button {
                        showBrowser = true
                    } label: {
                        Label("Read Article", systemImage: "doc.text")
                    }
                }
            }
            #endif
        }
        .task {
            await viewModel.loadComments()
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showBrowser) {
            if let url = viewModel.story.storyURL {
                BrowserView(url: url)
            }
        }
        #else
        .sheet(isPresented: $showBrowser) {
            if let url = viewModel.story.storyURL {
                BrowserView(url: url)
                    .frame(minWidth: 800, minHeight: 600)
            }
        }
        #endif
    }

    private var commentsHeader: some View {
        Text("Comments (\(viewModel.story.commentCount))")
            .font(.headline)
            .foregroundStyle(.secondary)
    }

    private var loadMoreButton: some View {
        Button {
            Task {
                await viewModel.loadMoreComments()
            }
        } label: {
            HStack {
                if viewModel.isLoadingMore {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Load More Comments (\(viewModel.remainingCount) remaining)")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoadingMore)
    }
}

struct StoryHeaderView: View {
    let story: HNStory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Domain
            if let domain = story.domain {
                HStack(spacing: 6) {
                    AsyncImage(url: faviconURL(for: domain)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image(systemName: "globe")
                            .font(.caption2)
                    }
                    .frame(width: 14, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 3))

                    Text(domain)
                        .font(.footnote)
                }
                .foregroundStyle(.secondary)
            }

            // Title
            Text(story.title)
                .font(.title3)
                .fontWeight(.semibold)

            // Story text (for Ask HN, Show HN, etc.)
            if let text = story.text {
                Text(text.strippingHTML())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Metadata
            HStack(spacing: 16) {
                Label(story.by, systemImage: "person")
                Label(story.relativeTime, systemImage: "clock")
                Label("\(story.score)", systemImage: "arrow.up")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func faviconURL(for domain: String) -> URL? {
        URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }
}

struct BrowserView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle(url.host ?? "Article")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    NavigationStack {
        CommentsView(story: HNStory(
            id: 1,
            title: "Show HN: I built something cool",
            by: "developer",
            score: 142,
            time: Int(Date().timeIntervalSince1970) - 7200,
            descendants: 45,
            url: "https://github.com/example/cool",
            text: nil,
            type: "story",
            kids: [100, 101, 102]
        ))
    }
}
