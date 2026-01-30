import SwiftUI

struct FeedView: View {
    @State private var viewModel = FeedViewModel()
    @State private var selectedStory: HNStory?
    @State private var showSummary = false

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.isLoading && viewModel.stories.isEmpty {
                        loadingView
                    } else if let error = viewModel.error, viewModel.stories.isEmpty {
                        errorView(error: error)
                    } else if viewModel.stories.isEmpty {
                        emptyView
                    } else {
                        storyList
                    }
                }

                // Floating AI Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingAIButton {
                            showSummary = true
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Hacker News")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            if viewModel.stories.isEmpty {
                await viewModel.loadTopStories()
            }
        }
        .sheet(item: $selectedStory) { story in
            if let url = story.storyURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showSummary) {
            SummaryView()
        }
    }

    private var storyList: some View {
        List {
            ForEach(viewModel.stories) { story in
                PostRowView(story: story)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if story.storyURL != nil {
                            selectedStory = story
                        }
                    }
                    .onAppear {
                        if story.id == viewModel.stories.last?.id {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading stories...")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(error: Error) -> some View {
        ContentUnavailableView {
            Label("Failed to Load", systemImage: "wifi.exclamationmark")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                Task {
                    await viewModel.loadTopStories()
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Stories", systemImage: "newspaper")
        } description: {
            Text("No stories available at the moment.")
        } actions: {
            Button("Refresh") {
                Task {
                    await viewModel.loadTopStories()
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

#Preview {
    FeedView()
}
