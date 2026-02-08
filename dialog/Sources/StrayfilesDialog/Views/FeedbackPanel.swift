import SwiftUI

/// Inline feedback text field for redirecting the agent.
/// Toggled open/closed with the F key.
/// Appears on all dialogs except notify.
struct FeedbackPanel: View {
  @Binding var isVisible: Bool
  let onSubmit: (String) -> Void

  @State private var feedbackText = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    if isVisible {
      VStack(alignment: .leading, spacing: 6) {
        Text("Redirect the agent:")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          TextField(
            "e.g., Skip this and focus on tests first",
            text: $feedbackText
          )
          .textFieldStyle(.plain)
          .font(.callout)
          .focused($isFocused)
          .onSubmit {
            guard !feedbackText.isEmpty else { return }
            onSubmit(feedbackText)
          }
          .accessibilityLabel("Feedback text")
          .accessibilityHint("Type a message to redirect the agent")

          Button("Send") {
            guard !feedbackText.isEmpty else { return }
            onSubmit(feedbackText)
          }
          .buttonStyle(.bordered)
          .disabled(feedbackText.isEmpty)
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(.ultraThinMaterial)
      )
      .onAppear {
        isFocused = true
      }
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Feedback panel")
      .accessibilityHint("Press F to toggle feedback panel")
    }
  }
}
