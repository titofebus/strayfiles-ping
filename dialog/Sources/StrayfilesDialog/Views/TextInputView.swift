// SPDX-License-Identifier: MIT
import SwiftUI

/// Free-form text input dialog with optional default value.
/// Enter submits the text.
struct TextInputView: View {
  let defaultValue: String?
  let onSubmit: (String) -> Void

  @State private var text: String = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      TextField("Type your response...", text: $text)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)
        .onSubmit {
          guard !text.isEmpty else { return }
          onSubmit(text)
        }
        .accessibilityLabel("Text input")
        .accessibilityHint("Type your response and press Enter")

      Button("Submit") {
        guard !text.isEmpty else { return }
        onSubmit(text)
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.defaultAction)
      .disabled(text.isEmpty)
    }
    .onAppear {
      text = defaultValue ?? ""
      isFocused = true
    }
  }
}
