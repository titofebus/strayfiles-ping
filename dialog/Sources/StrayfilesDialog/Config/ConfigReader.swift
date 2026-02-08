import Foundation

/// Reads and parses ~/.config/strayfiles-ping/config.toml.
/// Simple line-by-line TOML parser for flat config structure.
/// Falls back to built-in defaults if file is missing or malformed.
enum ConfigReader {

  /// The config file path.
  static let configPath: String = {
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    return "\(home)/.config/strayfiles-ping/config.toml"
  }()

  /// Reads and parses the config file.
  /// @returns Parsed DialogConfig, or defaults if file is missing/malformed
  static func read() -> DialogConfig {
    guard let contents = try? String(contentsOfFile: configPath, encoding: .utf8)
    else {
      return .defaults
    }
    return parse(contents)
  }

  /// Writes a single key-value pair to the config file.
  /// Creates the file and directories if they don't exist.
  /// @param key The TOML key in dot notation (e.g., "snooze.until")
  /// @param value The value to write
  static func write(key: String, value: String) {
    let fileURL = URL(fileURLWithPath: configPath)
    let directory = fileURL.deletingLastPathComponent()

    // Create directory if needed
    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true
    )

    // Read existing content or start fresh
    var lines: [String]
    if let existing = try? String(contentsOfFile: configPath, encoding: .utf8) {
      lines = existing.components(separatedBy: "\n")
    } else {
      lines = []
    }

    let parts = key.split(separator: ".", maxSplits: 1)
    guard parts.count == 2 else { return }
    let section = String(parts[0])
    let field = String(parts[1])

    // Find or create section, then set the value
    var sectionIndex: Int?
    var fieldIndex: Int?

    for (index, line) in lines.enumerated() {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed == "[\(section)]" {
        sectionIndex = index
      } else if sectionIndex != nil,
        trimmed.hasPrefix("[") && trimmed.hasSuffix("]")
      {
        // Hit next section without finding the field
        break
      } else if sectionIndex != nil {
        // Exact field match: field name followed by = or space
        let fieldName = trimmed.split(separator: "=", maxSplits: 1).first
          .map { $0.trimmingCharacters(in: .whitespaces) }
        if fieldName == field {
          fieldIndex = index
          break
        }
      }
    }

    let formattedValue = formatTomlValue(value)
    let lineContent = "\(field) = \(formattedValue)"

    if let fieldIdx = fieldIndex {
      lines[fieldIdx] = lineContent
    } else if let sectionIdx = sectionIndex {
      lines.insert(lineContent, at: sectionIdx + 1)
    } else {
      if let lastLine = lines.last, !lastLine.isEmpty {
        lines.append("")
      }
      lines.append("[\(section)]")
      lines.append(lineContent)
    }

    // Write atomically
    let content = lines.joined(separator: "\n")
    try? content.write(toFile: configPath, atomically: true, encoding: .utf8)
  }

  // MARK: - Private

  /// Parses TOML content into a DialogConfig.
  /// Internal visibility for unit testing.
  /// @param content The raw TOML file content
  /// @returns Parsed config with defaults for missing values
  static func parse(_ content: String) -> DialogConfig {
    var config = DialogConfig.defaults
    var currentSection = ""

    for line in content.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)

      // Skip comments and empty lines
      if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

      // Section header
      if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
        currentSection = String(
          trimmed.dropFirst().dropLast()
        )
        continue
      }

      // Key = value
      guard let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
      let key = trimmed[trimmed.startIndex..<equalsIndex]
        .trimmingCharacters(in: .whitespaces)
      let rawValue = trimmed[trimmed.index(after: equalsIndex)...]
        .trimmingCharacters(in: .whitespaces)
      let value = stripTomlQuotes(stripInlineComment(rawValue))

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

  /// Parses a field in the [dialog] section.
  /// @param key The field name
  /// @param value The string value
  /// @param config The settings struct to mutate
  private static func parseDialogField(
    key: String, value: String, config: inout DialogSettings
  ) {
    switch key {
    case "enabled":
      config.enabled = parseBool(value) ?? config.enabled
    case "position":
      config.position = DialogPosition(rawValue: value) ?? config.position
    case "timeout":
      if let intVal = Int(value) {
        config.timeout = min(max(intVal, 1), 3600)
      }
    case "sound":
      config.sound = SoundType(rawValue: value) ?? config.sound
    case "always_on_top":
      config.alwaysOnTop = parseBool(value) ?? config.alwaysOnTop
    case "cooldown":
      config.cooldown = parseBool(value) ?? config.cooldown
    case "cooldown_duration":
      if let doubleVal = Double(value) {
        config.cooldownDuration = min(max(doubleVal, 0.1), 3.0)
      }
    default:
      break
    }
  }

  /// Parses a field in the [theme] section.
  /// @param key The field name
  /// @param value The string value
  /// @param config The settings struct to mutate
  private static func parseThemeField(
    key: String, value: String, config: inout ThemeSettings
  ) {
    if key == "accent" {
      config.accent = value
    }
  }

  /// Parses a field in the [routing] section.
  /// @param key The field name
  /// @param value The string value
  /// @param config The settings struct to mutate
  private static func parseRoutingField(
    key: String, value: String, config: inout RoutingSettings
  ) {
    switch key {
    case "idle_threshold":
      if let intVal = Int(value) {
        config.idleThreshold = min(max(intVal, 30), 600)
      }
    case "prefer":
      config.prefer = RoutingPreference(rawValue: value) ?? config.prefer
    default:
      break
    }
  }

  /// Parses a field in the [snooze] section.
  /// @param key The field name
  /// @param value The string value
  /// @param config The settings struct to mutate
  private static func parseSnoozeField(
    key: String, value: String, config: inout SnoozeConfig
  ) {
    if key == "until" && !value.isEmpty {
      let formatter = ISO8601DateFormatter()
      config.until = formatter.date(from: value)
    }
  }

  /// Parses a TOML boolean value.
  /// @param value The string to parse
  /// @returns The boolean value, or nil if not a valid boolean
  private static func parseBool(_ value: String) -> Bool? {
    switch value.lowercased() {
    case "true": return true
    case "false": return false
    default: return nil
    }
  }

  /// Strips surrounding quotes from a TOML value.
  /// @param value The raw TOML value string
  /// @returns The unquoted string
  private static func stripTomlQuotes(_ value: String) -> String {
    if value.hasPrefix("\"") && value.hasSuffix("\"") && value.count >= 2 {
      return String(value.dropFirst().dropLast())
    }
    return value
  }

  /// Strips inline comments from a TOML value.
  /// Handles quoted strings by not stripping # inside quotes.
  /// @param value The raw TOML value (after key = )
  /// @returns Value with inline comment removed
  private static func stripInlineComment(_ value: String) -> String {
    // If the value starts with a quote, find the closing quote first
    if value.hasPrefix("\"") {
      if let closingQuote = value.dropFirst().firstIndex(of: "\"") {
        let endIndex = value.index(after: closingQuote)
        return String(value[value.startIndex..<endIndex])
      }
      return value
    }
    // For unquoted values, strip everything after #
    if let hashIndex = value.firstIndex(of: "#") {
      return value[value.startIndex..<hashIndex]
        .trimmingCharacters(in: .whitespaces)
    }
    return value
  }

  /// Formats a value for TOML output.
  /// @param value The value to format
  /// @returns TOML-formatted string
  private static func formatTomlValue(_ value: String) -> String {
    if value == "true" || value == "false" {
      return value
    }
    if Int(value) != nil || Double(value) != nil {
      return value
    }
    return "\"\(value)\""
  }
}
