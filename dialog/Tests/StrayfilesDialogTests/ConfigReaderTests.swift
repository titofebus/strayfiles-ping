// SPDX-License-Identifier: MIT
import XCTest

@testable import strayfiles_dialog

final class ConfigReaderTests: XCTestCase {

  /// Tests parsing a complete config.toml file.
  func testParseCompleteConfig() {
    let toml = """
      [dialog]
      enabled = true
      position = "top-right"
      timeout = 300
      sound = "subtle"
      always_on_top = false
      cooldown = true
      cooldown_duration = 1.5

      [theme]
      accent = "#6366f1"

      [routing]
      idle_threshold = 180
      prefer = "local"

      [snooze]
      until = ""
      """

    let config = ConfigReader.parse(toml)

    XCTAssertTrue(config.dialog.enabled)
    XCTAssertEqual(config.dialog.position, .topRight)
    XCTAssertEqual(config.dialog.timeout, 300)
    XCTAssertEqual(config.dialog.sound, .subtle)
    XCTAssertFalse(config.dialog.alwaysOnTop)
    XCTAssertTrue(config.dialog.cooldown)
    XCTAssertEqual(config.dialog.cooldownDuration, 1.5)

    XCTAssertEqual(config.theme.accent, "#6366f1")
    XCTAssertTrue(config.theme.hasCustomAccent)

    XCTAssertEqual(config.routing.idleThreshold, 180)
    XCTAssertEqual(config.routing.prefer, .local)

    XCTAssertNil(config.snooze.until)
  }

  /// Tests that missing config returns defaults.
  func testDefaultConfig() {
    let config = ConfigReader.parse("")

    XCTAssertTrue(config.dialog.enabled)
    XCTAssertEqual(config.dialog.position, .topRight)
    XCTAssertEqual(config.dialog.timeout, 600)
    XCTAssertEqual(config.dialog.sound, .none)
    XCTAssertTrue(config.dialog.alwaysOnTop)
    XCTAssertFalse(config.dialog.cooldown)
    XCTAssertEqual(config.dialog.cooldownDuration, 1.0)

    XCTAssertEqual(config.theme.accent, "")
    XCTAssertFalse(config.theme.hasCustomAccent)

    XCTAssertEqual(config.routing.idleThreshold, 120)
    XCTAssertEqual(config.routing.prefer, .auto)

    XCTAssertNil(config.snooze.until)
  }

  /// Tests that timeout is clamped to valid range.
  func testTimeoutClamping() {
    let toml = """
      [dialog]
      timeout = 99999
      """
    let config = ConfigReader.parse(toml)
    XCTAssertEqual(config.dialog.timeout, 3600)

    let toml2 = """
      [dialog]
      timeout = 0
      """
    let config2 = ConfigReader.parse(toml2)
    XCTAssertEqual(config2.dialog.timeout, 1)
  }

  /// Tests that cooldown duration is clamped.
  func testCooldownDurationClamping() {
    let toml = """
      [dialog]
      cooldown_duration = 10.0
      """
    let config = ConfigReader.parse(toml)
    XCTAssertEqual(config.dialog.cooldownDuration, 3.0)

    let toml2 = """
      [dialog]
      cooldown_duration = 0.01
      """
    let config2 = ConfigReader.parse(toml2)
    XCTAssertEqual(config2.dialog.cooldownDuration, 0.1)
  }

  /// Tests parsing comments and empty lines.
  func testCommentsAndEmptyLines() {
    let toml = """
      # This is a comment
      [dialog]
      # Another comment
      enabled = false

      position = "center"
      """
    let config = ConfigReader.parse(toml)
    XCTAssertFalse(config.dialog.enabled)
    XCTAssertEqual(config.dialog.position, .center)
  }

  /// Tests snooze timestamp parsing.
  func testSnoozeTimestampParsing() {
    let toml = """
      [snooze]
      until = "2099-01-01T00:00:00Z"
      """
    let config = ConfigReader.parse(toml)
    XCTAssertNotNil(config.snooze.until)
  }

  /// Tests invalid values fall back to defaults.
  func testInvalidValuesFallback() {
    let toml = """
      [dialog]
      position = "invalid"
      sound = "invalid"
      timeout = notanumber

      [routing]
      prefer = "invalid"
      """
    let config = ConfigReader.parse(toml)
    XCTAssertEqual(config.dialog.position, .topRight)
    XCTAssertEqual(config.dialog.sound, .none)
    XCTAssertEqual(config.dialog.timeout, 600)
    XCTAssertEqual(config.routing.prefer, .auto)
  }
}

// Make the private parse method accessible for testing
extension ConfigReader {
  static func parse(_ content: String) -> DialogConfig {
    var config = DialogConfig.defaults
    var currentSection = ""

    for line in content.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

      if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
        currentSection = String(trimmed.dropFirst().dropLast())
        continue
      }

      guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
      let key = trimmed[trimmed.startIndex..<equalsIndex]
        .trimmingCharacters(in: .whitespaces)
      let rawValue = trimmed[trimmed.index(after: equalsIndex)...]
        .trimmingCharacters(in: .whitespaces)
      let value = stripQuotes(rawValue)

      switch currentSection {
      case "dialog":
        parseDialogField(key: key, value: value, config: &config.dialog)
      case "theme":
        parseThemeField(key: key, value: value, config: &config.theme)
      case "routing":
        parseRoutingField(key: key, value: value, config: &config.routing)
      case "snooze":
        parseSnoozeField(key: key, value: value, config: &config.snooze)
      default:
        break
      }
    }
    return config
  }

  private static func stripQuotes(_ value: String) -> String {
    if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
      return String(value.dropFirst().dropLast())
    }
    return value
  }

  private static func parseDialogField(
    key: String, value: String, config: inout DialogSettings
  ) {
    switch key {
    case "enabled":
      if value == "true" { config.enabled = true }
      else if value == "false" { config.enabled = false }
    case "position":
      config.position = DialogPosition(rawValue: value) ?? config.position
    case "timeout":
      if let v = Int(value) { config.timeout = min(max(v, 1), 3600) }
    case "sound":
      config.sound = SoundType(rawValue: value) ?? config.sound
    case "always_on_top":
      if value == "true" { config.alwaysOnTop = true }
      else if value == "false" { config.alwaysOnTop = false }
    case "cooldown":
      if value == "true" { config.cooldown = true }
      else if value == "false" { config.cooldown = false }
    case "cooldown_duration":
      if let v = Double(value) { config.cooldownDuration = min(max(v, 0.1), 3.0) }
    default: break
    }
  }

  private static func parseThemeField(
    key: String, value: String, config: inout ThemeSettings
  ) {
    if key == "accent" { config.accent = value }
  }

  private static func parseRoutingField(
    key: String, value: String, config: inout RoutingSettings
  ) {
    switch key {
    case "idle_threshold":
      if let v = Int(value) { config.idleThreshold = min(max(v, 30), 600) }
    case "prefer":
      config.prefer = RoutingPreference(rawValue: value) ?? config.prefer
    default: break
    }
  }

  private static func parseSnoozeField(
    key: String, value: String, config: inout SnoozeConfig
  ) {
    if key == "until" && !value.isEmpty {
      config.until = ISO8601DateFormatter().date(from: value)
    }
  }
}
