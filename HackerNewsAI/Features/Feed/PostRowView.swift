import SwiftUI

struct PostRowView: View {
    let story: HNStory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(story.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(3)

            HStack(spacing: 12) {
                Label("\(story.score)", systemImage: "arrow.up")

                Label("\(story.commentCount)", systemImage: "bubble.right")

                if let domain = story.domain {
                    Text(domain)
                        .lineLimit(1)
                }

                Text(story.relativeTime)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("by \(story.by)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        PostRowView(story: HNStory(
            id: 1,
            title: "Show HN: I built a new database in Rust that's 10x faster",
            by: "rustfan",
            score: 342,
            time: Int(Date().timeIntervalSince1970) - 3600,
            descendants: 89,
            url: "https://github.com/example/rustdb",
            text: nil,
            type: "story"
        ))

        PostRowView(story: HNStory(
            id: 2,
            title: "Ask HN: What's the best way to learn systems programming?",
            by: "curious_dev",
            score: 156,
            time: Int(Date().timeIntervalSince1970) - 7200,
            descendants: 234,
            url: nil,
            text: "I want to learn...",
            type: "story"
        ))
    }
}
