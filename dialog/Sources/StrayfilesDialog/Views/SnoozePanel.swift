import SwiftUI

/// Snooze duration picker overlay.
/// Five preset durations: 1, 5, 15, 30, 60 minutes.
/// Toggled open/closed with the S key.
struct SnoozePanel: View {
  @Binding var isVisible: Bool
  let onSnooze: (Int) -> Void

  private let durations = [1, 5, 15, 30, 60]

  var body: some View {
    if isVisible {
      VStack(alignment: .leading, spacing: 6) {
        Text("Snooze for:")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: 4) {
          ForEach(durations, id: \.self) { minutes in
            Button(action: { onSnooze(minutes) }) {
              Text(formatDuration(minutes))
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Snooze for \(minutes) minutes")
          }
        }
      }
      .padding(8)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(.ultraThinMaterial)
      )
      .accessibilityElement(children: .contain)
      .accessibilityLabel("Snooze options")
      .accessibilityHint("Press S to toggle snooze panel")
    }
  }

  /// Formats a duration for the button label.
  /// @param minutes The duration in minutes
  /// @returns Formatted string (e.g., "5m", "1h")
  private func formatDuration(_ minutes: Int) -> String {
    if minutes >= 60 {
      return "\(minutes / 60)h"
    }
    return "\(minutes)m"
  }
}
