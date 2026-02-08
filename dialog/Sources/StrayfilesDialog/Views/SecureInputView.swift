import SwiftUI

/// Masked text input for sensitive values (API keys, tokens).
/// Value is never logged or persisted.
/// Enter submits the text.
struct SecureInputView: View {
  let onSubmit: (String) -> Void

  @State private var text: String = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      SecureField("Enter sensitive value...", text: $text)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)
        .onSubmit {
          guard !text.isEmpty else { return }
          onSubmit(text)
        }
        .accessibilityLabel("Secure text input")
        .accessibilityHint("Type a sensitive value and press Enter")

      Button("Submit") {
        guard !text.isEmpty else { return }
        onSubmit(text)
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.defaultAction)
      .disabled(text.isEmpty)
    }
    .onAppear {
      isFocused = true
    }
  }
}
