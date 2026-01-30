import SwiftUI

struct PostRowView: View {
    let story: HNStory

    var body: some View {
        HStack(alignment: .center) {
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
                        }
                        .frame(width: 16, height: 16)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text(domain)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                }

                // Title
                Text(story.title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                // Metadata row
                HStack(spacing: 16) {
                    Label(story.by, systemImage: "person")

                    Label(story.relativeTime, systemImage: "calendar")

                    Label("\(story.score)", systemImage: "hand.thumbsup")

                    Label("\(story.commentCount)", systemImage: "list.bullet")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }

    private func faviconURL(for domain: String) -> URL? {
        URL(string: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64")
    }
}

#Preview {
    List {
        PostRowView(story: HNStory(
            id: 1,
            title: "Microsoft Just Killed the \"Cover for Me\" Excuse: 365 Now Tracks You in Real-Time",
            by: "imalerba",
            score: 105,
            time: Int(Date().timeIntervalSince1970) - 3300,
            descendants: 91,
            url: "https://ztechtalk.com/article",
            text: nil,
            type: "story"
        ))

        PostRowView(story: HNStory(
            id: 2,
            title: "Moltbook is the most interesting place on the internet",
            by: "swolpers",
            score: 27,
            time: Int(Date().timeIntervalSince1970) - 3480,
            descendants: 20,
            url: "https://simonwillison.net/post",
            text: nil,
            type: "story"
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
            type: "story"
        ))

        PostRowView(story: HNStory(
            id: 4,
            title: "Moltbook",
            by: "teej",
            score: 897,
            time: Int(Date().timeIntervalSince1970) - 50400,
            descendants: 453,
            url: "https://www.moltbook.com",
            text: nil,
            type: "story"
        ))
    }
    .listStyle(.plain)
}
