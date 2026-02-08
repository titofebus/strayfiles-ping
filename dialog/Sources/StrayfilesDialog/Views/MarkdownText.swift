import SwiftUI

/// Renders basic Markdown as styled text.
/// Supports **bold**, *italic*, `inline code`, and [links](url).
/// Uses system font at system sizes — no custom styling.
struct MarkdownText: View {
  let text: String

  var body: some View {
    Text(LocalizedStringKey(text))
      .font(.body)
      .tint(.accentColor)
      .textSelection(.enabled)
  }
}
