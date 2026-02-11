// SPDX-License-Identifier: MIT
import Foundation

/// Represents the current snooze state, read from and written to config.toml.
struct SnoozeState {
  /// The ISO 8601 timestamp when the snooze expires.
  /// nil means not snoozed.
  var until: Date?

  /// Whether the snooze is currently active.
  var isActive: Bool {
    guard let until else { return false }
    return until > Date()
  }

  /// Remaining seconds until snooze expires. 0 if not snoozed.
  var remainingSeconds: Int {
    guard let until, isActive else { return 0 }
    return max(0, Int(until.timeIntervalSinceNow))
  }

  /// Creates a new snooze state with the given duration in minutes.
  /// @param minutes Number of minutes to snooze
  /// @returns A new SnoozeState with the expiry set
  static func snooze(minutes: Int) -> SnoozeState {
    SnoozeState(
      until: Date().addingTimeInterval(TimeInterval(minutes * 60))
    )
  }

  /// An empty (not snoozed) state.
  static let none = SnoozeState(until: nil)
}
