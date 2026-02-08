import SwiftUI

/// Displays the project folder name above the dialog message.
/// Plain text, no icon, no badge styling.
/// Shows full path on hover/tooltip.
struct ProjectBadge: View {
  /// The project folder name (e.g., "my-project").
  let name: String?

  /// The full project path for tooltip.
  let path: String?

  var body: some View {
    if let name, !name.isEmpty {
      Text(name)
        .font(.caption)
        .foregroundStyle(.secondary)
        .help(path ?? name)
    }
  }
}
