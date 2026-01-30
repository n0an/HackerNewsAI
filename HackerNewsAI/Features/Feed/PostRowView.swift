import SwiftUI

struct PostRowView: View {
    let story: HNStory

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .font(.headline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(3)

            // Metadata row
            HStack(spacing: 12) {
                MetadataItem(icon: "person", text: story.by)
                MetadataItem(icon: "calendar", text: story.relativeTime)
                MetadataItem(icon: "hand.thumbsup", text: "\(story.score)")
                MetadataItem(icon: "list.bullet", text: "\(story.commentCount)")
            }
        }
        .padding(.vertical, 8)
    }

    private func faviconURL(for domain: String) -> URL? {
        URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }
}

struct MetadataItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 20, height: 20)
                .background(Color(.systemGray5))
                .clipShape(Circle())

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    List {
        PostRowView(story: HNStory(
            id: 1,
            title: "GOG: Linux \"the next major frontier\" for gaming as it works on a native client",
            by: "franczesko",
            score: 493,
            time: Int(Date().timeIntervalSince1970) - 36000,
            descendants: 285,
            url: "https://xda-developers.com/article",
            text: nil,
            type: "story",
            kids: [100, 101, 102]
        ))

        PostRowView(story: HNStory(
            id: 2,
            title: "Microsoft Just Killed the \"Cover for Me\" Excuse: 365 Now Tracks You in Real-Time",
            by: "imalerba",
            score: 105,
            time: Int(Date().timeIntervalSince1970) - 3300,
            descendants: 91,
            url: "https://ztechtalk.com/article",
            text: nil,
            type: "story",
            kids: [200, 201]
        ))

        PostRowView(story: HNStory(
            id: 3,
            title: "Show HN: Amla Sandbox – WASM bash shell sandbox for AI agents",
            by: "souvik1997",
            score: 64,
            time: Int(Date().timeIntervalSince1970) - 14400,
            descendants: 36,
            url: "https://github.com/example/amla",
            text: nil,
            type: "story",
            kids: nil
        ))
    }
    .listStyle(.plain)
}
