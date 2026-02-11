// SPDX-License-Identifier: MIT
import AppKit

/// Accessibility utilities for dialog views.
/// Provides labels, hints, and respects system preferences.
enum AccessibilityHelper {

  /// Whether the system prefers reduced motion.
  /// Since we have no custom animations, this is informational only.
  static var prefersReducedMotion: Bool {
    NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  /// Builds a combined accessibility label from title and message.
  /// @param title The optional dialog title
  /// @param message The dialog message
  /// @returns A descriptive label for VoiceOver
  static func dialogLabel(title: String?, message: String) -> String {
    if let title, !title.isEmpty {
      return "\(title). \(message)"
    }
    return message
  }

  /// Returns an accessibility hint for a dialog type.
  /// @param type The dialog type
  /// @returns A contextual hint for VoiceOver
  static func dialogHint(for type: DialogType) -> String {
    switch type {
    case .notify:
      return "Notification"
    case .confirmation:
      return "Press Enter to confirm or Escape to cancel"
    case .choice:
      return "Use arrow keys to select an option, then press Enter"
    case .multiSelect:
      return "Use arrow keys and Space to toggle options, then press Enter"
    case .text:
      return "Type your response and press Enter"
    case .secureText:
      return "Type your secure response and press Enter"
    case .questions:
      return "Answer each question in sequence"
    }
  }
}
