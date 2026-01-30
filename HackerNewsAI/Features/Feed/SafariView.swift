import SwiftUI
import WebKit

struct SafariView: View {
    let url: URL

    var body: some View {
        WebView(url: url)
    }
}

#Preview {
    SafariView(url: URL(string: "https://news.ycombinator.com")!)
}
