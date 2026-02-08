import SwiftUI

/// Simple yes/no confirmation dialog.
/// Enter confirms, Escape cancels.
struct ConfirmationView: View {
  let onConfirm: (String) -> Void

  var body: some View {
    HStack(spacing: 8) {
      Button("No") {
        onConfirm("no")
      }
      .buttonStyle(.bordered)
      .accessibilityLabel("No")

      Button("Yes") {
        onConfirm("yes")
      }
      .buttonStyle(.borderedProminent)
      .keyboardShortcut(.defaultAction)
      .accessibilityLabel("Yes")
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}
