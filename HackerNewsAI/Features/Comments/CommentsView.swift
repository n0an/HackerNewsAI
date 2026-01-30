import SwiftUI
import WebKit

struct CommentsView: View {
    @State private var viewModel: CommentsViewModel
    @State private var showBrowser = false

    init(story: HNStory) {
        _viewModel = State(initialValue: CommentsViewModel(story: story))
    }

    var body: some View {
        List {
            // Story header section
            Section {
                StoryHeaderView(story: viewModel.story)
            }

            // Comments section
            Section {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowSeparator(.hidden)
                } else if let error = viewModel.error {
                    Text("Failed to load comments: \(error.localizedDescription)")
                        .foregroundStyle(.secondary)
                } else if viewModel.comments.isEmpty {
                    Text("No comments yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(comment: comment)
                    }
                }
            } header: {
                Text("Comments (\(viewModel.story.commentCount))")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Discussion")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if viewModel.story.storyURL != nil {
                    Button {
                        showBrowser = true
                    } label: {
                        Label("Read Article", systemImage: "doc.text")
                    }
                }
            }
        }
        .task {
            await viewModel.loadComments()
        }
        .fullScreenCover(isPresented: $showBrowser) {
            if let url = viewModel.story.storyURL {
                BrowserView(url: url)
            }
        }
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
        .padding(.vertical, 4)
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
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
