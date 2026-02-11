// SPDX-License-Identifier: MIT
import Foundation

/// Parsed configuration from ~/.config/strayfiles-ping/config.toml.
/// Both the Rust MCP and Swift dialog CLI read this file.
struct DialogConfig {
  var dialog: DialogSettings
  var theme: ThemeSettings
  var routing: RoutingSettings
  var snooze: SnoozeConfig

  /// Built-in defaults when no config file exists.
  static let defaults = DialogConfig(
    dialog: .defaults,
    theme: .defaults,
    routing: .defaults,
    snooze: .defaults
  )
}

/// Settings under the [dialog] section.
struct DialogSettings {
  /// Whether local macOS dialogs are enabled.
  var enabled: Bool
  /// Dialog position on screen.
  var position: DialogPosition
  /// Default timeout in seconds.
  var timeout: Int
  /// Sound to play on dialog appearance.
  var sound: SoundType
  /// Whether the dialog stays on top of other windows.
  var alwaysOnTop: Bool
  /// Whether button cooldown is enabled.
  var cooldown: Bool
  /// Cooldown duration in seconds (0.1 - 3.0).
  var cooldownDuration: Double

  static let defaults = DialogSettings(
    enabled: true,
    position: .topRight,
    timeout: 600,
    sound: .none,
    alwaysOnTop: true,
    cooldown: false,
    cooldownDuration: 1.0
  )
}

/// Dialog position on screen.
enum DialogPosition: String {
  case center
  case topLeft = "top-left"
  case topRight = "top-right"
  case bottomRight = "bottom-right"
}

/// System sound to play when a dialog appears.
enum SoundType: String {
  case none
  case subtle
  case pop
  case chime
}

/// Settings under the [theme] section.
struct ThemeSettings {
  /// Hex color for accent (e.g., "#6366f1"). Empty = system accent.
  var accent: String

  /// Whether a custom accent color is set.
  var hasCustomAccent: Bool {
    !accent.isEmpty
  }

  static let defaults = ThemeSettings(accent: "")
}

/// Settings under the [routing] section.
struct RoutingSettings {
  /// Seconds of inactivity before remote fallback.
  var idleThreshold: Int
  /// Routing preference.
  var prefer: RoutingPreference

  static let defaults = RoutingSettings(
    idleThreshold: 120,
    prefer: .auto
  )
}

/// Routing preference for smart routing.
enum RoutingPreference: String {
  case auto
  case local
  case remote
}

/// Settings under the [snooze] section.
struct SnoozeConfig {
  /// ISO 8601 timestamp when snooze expires. nil = not snoozed.
  var until: Date?

  static let defaults = SnoozeConfig(until: nil)
}
