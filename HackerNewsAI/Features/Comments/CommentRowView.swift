import SwiftUI

struct CommentRowView: View {
    let node: CommentNode
    @Binding var collapsedIDs: Set<Int>

    private var isCollapsed: Bool {
        collapsedIDs.contains(node.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Comment header
            HStack(spacing: 8) {
                if node.depth > 0 {
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 6, height: 6)
                }

                Image(systemName: "person")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(node.comment.author)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(node.comment.relativeTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if node.hasChildren {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isCollapsed {
                                collapsedIDs.remove(node.id)
                            } else {
                                collapsedIDs.insert(node.id)
                            }
                        }
                    } label: {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Comment content with vertical bar
            if !isCollapsed {
                HStack(alignment: .top, spacing: 12) {
                    // Vertical thread indicator
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 2)

                    Text(node.comment.content.strippingHTML())
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 12)

                // Nested replies
                if !node.children.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(node.children) { child in
                            CommentRowView(node: child, collapsedIDs: $collapsedIDs)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
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
    ScrollView {
        CommentRowView(
            node: CommentNode(
                id: 1,
                comment: HNComment(
                    id: 1,
                    by: "monkeywithdarts",
                    text: "I am missing some context on this. Is this really from Sam Altman on... Reddit? Or did this pop up on Moltbook... from an Agent, or Sam Altman?",
                    time: Int(Date().timeIntervalSince1970) - 1260,
                    parent: 100,
                    kids: [2],
                    type: "comment"
                ),
                children: [
                    CommentNode(
                        id: 2,
                        comment: HNComment(
                            id: 2,
                            by: "wahnfrieden",
                            text: "it is obviously not sam altman and it's not reddit. you're seeing a post on moltbook.",
                            time: Int(Date().timeIntervalSince1970) - 1080,
                            parent: 1,
                            kids: nil,
                            type: "comment"
                        ),
                        children: [],
                        depth: 1
                    )
                ],
                depth: 0
            ),
            collapsedIDs: .constant([])
        )
        .padding()
    }
}
