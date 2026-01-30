import SwiftUI

struct CommentRowView: View {
    let comment: HNComment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author and time
            HStack(spacing: 8) {
                Text(comment.author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(comment.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Comment text (HTML stripped)
            Text(comment.content.strippingHTML())
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }
}

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }

        // Fallback: basic tag stripping
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}

#Preview {
    List {
        CommentRowView(comment: HNComment(
            id: 1,
            by: "pg",
            text: "This is a <b>great</b> comment with some <i>HTML</i> formatting and a <a href=\"https://example.com\">link</a>.",
            time: Int(Date().timeIntervalSince1970) - 3600,
            parent: 100,
            kids: [2, 3, 4],
            type: "comment"
        ))
    }
}
