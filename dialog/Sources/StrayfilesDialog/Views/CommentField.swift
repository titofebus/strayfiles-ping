// SPDX-License-Identifier: MIT
import SwiftUI

/// Optional freeform note field at the bottom of every dialog.
/// Collapsed by default — expands when clicked or tabbed into.
struct CommentField: View {
  @Binding var comment: String
  @State private var isExpanded = false
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if isExpanded || !comment.isEmpty {
        TextField("Add a note (optional)", text: $comment)
          .textFieldStyle(.plain)
          .font(.caption)
          .focused($isFocused)
          .accessibilityLabel("Optional note")
          .accessibilityHint("Add a note alongside your answer")
      } else {
        Button(action: {
          isExpanded = true
          DispatchQueue.main.async {
            isFocused = true
          }
        }) {
          Text("Add a note...")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add optional note")
      }
    }
  }
}
