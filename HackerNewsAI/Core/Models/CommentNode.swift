import Foundation

struct CommentNode: Identifiable {
    let id: Int
    let comment: HNComment
    var children: [CommentNode]
    var isCollapsed: Bool = false
    let depth: Int

    var hasChildren: Bool {
        !children.isEmpty
    }
}
