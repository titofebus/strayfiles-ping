// SPDX-License-Identifier: MIT
import SwiftUI

/// Resolves the dialog accent color using a priority chain:
/// 1. Explicit hex in config.toml [theme] accent
/// 2. Strayfiles app theme from ~/.strayfiles/config.csv
/// 3. Default Strayfiles brand color (#EBD255)
enum AccentResolver {

  /// Default Strayfiles brand accent (yellow).
  static let defaultAccent = Color(red: 235 / 255, green: 210 / 255, blue: 85 / 255)

  /// Resolves the accent color.
  /// @param config The theme settings from config.toml
  /// @returns The resolved accent color
  static func resolve(config: ThemeSettings) -> Color {
    // Priority 1: Explicit hex override in config.toml
    if config.hasCustomAccent, let color = parseHex(config.accent) {
      return color
    }

    // Priority 2: Read Strayfiles app theme
    if let theme = readStrayfilesTheme() {
      return accentColor(for: theme)
    }

    // Priority 3: Default brand color
    return defaultAccent
  }

  // MARK: - Strayfiles Theme Detection

  /// Reads the last_theme value from ~/.strayfiles/config.csv.
  /// @returns The theme name, or nil if Strayfiles is not installed
  static func readStrayfilesTheme() -> String? {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let csvPath = "\(home)/.strayfiles/config.csv"

    guard let contents = try? String(contentsOfFile: csvPath, encoding: .utf8) else {
      return nil
    }

    // CSV format: key,value (one pair per line)
    for line in contents.components(separatedBy: "\n") {
      let parts = line.split(separator: ",", maxSplits: 1)
      if parts.count == 2 && parts[0] == "last_theme" {
        let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
      }
    }

    return nil
  }

  /// Maps a Strayfiles theme name to its accent color.
  /// Colors match the Rust TUI theme definitions in backend/tui/src/theme/.
  /// @param theme The theme identifier
  /// @returns The accent color for the theme
  static func accentColor(for theme: String) -> Color {
    switch theme {
    case "dark":
      // ACCENT_500: rgb(235, 210, 85)
      Color(red: 235 / 255, green: 210 / 255, blue: 85 / 255)

    case "light":
      // ACCENT_600: rgb(210, 185, 70)
      Color(red: 210 / 255, green: 185 / 255, blue: 70 / 255)

    case "pastel":
      // rgb(142, 202, 230)
      Color(red: 142 / 255, green: 202 / 255, blue: 230 / 255)

    case "sunrise":
      // ORANGE_ACCENT: rgb(245, 130, 50)
      Color(red: 245 / 255, green: 130 / 255, blue: 50 / 255)

    case "midnight":
      // ACCENT_500: rgb(235, 210, 85)
      Color(red: 235 / 255, green: 210 / 255, blue: 85 / 255)

    case "forest":
      // GREEN_ACCENT: rgb(90, 180, 100)
      Color(red: 90 / 255, green: 180 / 255, blue: 100 / 255)

    default:
      defaultAccent
    }
  }

  // MARK: - Hex Parsing

  /// Parses a hex color string (e.g., "#EBD255" or "EBD255").
  /// @param hex The hex color string
  /// @returns A Color, or nil if the string is invalid
  static func parseHex(_ hex: String) -> Color? {
    var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleaned.hasPrefix("#") {
      cleaned = String(cleaned.dropFirst())
    }

    guard cleaned.count == 6 else { return nil }

    var rgb: UInt64 = 0
    guard Scanner(string: cleaned).scanHexInt64(&rgb) else { return nil }

    let r = Double((rgb >> 16) & 0xFF) / 255
    let g = Double((rgb >> 8) & 0xFF) / 255
    let b = Double(rgb & 0xFF) / 255

    return Color(red: r, green: g, blue: b)
  }
}
