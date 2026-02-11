// SPDX-License-Identifier: MIT
import Foundation

/// JSON input model received from the Rust MCP server.
/// Matches the `ping` tool parameters.
struct InputPayload: Codable {
  /// The notification or dialog text. Supports basic Markdown.
  let message: String

  /// Optional dialog title displayed above the message body.
  let title: String?

  /// The type of dialog to show. nil defaults to message-with-options.
  let inputType: DialogType?

  /// Quick-reply buttons or choice list (max 20).
  let options: [String]?

  /// Description text per option (must match options length).
  let descriptions: [String]?

  /// Pre-selected option for choice input.
  let defaultSelection: String?

  /// Pre-filled value for text input.
  let defaultValue: String?

  /// Multi-question layout mode.
  let mode: QuestionMode?

  /// Questions array for wizard/accordion mode.
  let questions: [Question]?

  /// Per-call flag to play system notification sound (notify type only).
  let sound: Bool?

  /// Timeout in seconds before auto-dismiss.
  let timeout: Int?

  /// Project folder name for context badge.
  let project: String?

  /// Full project path for tooltip.
  let projectPath: String?

  /// The resolved dialog type, falling back to a sensible default.
  var resolvedType: DialogType {
    if let inputType {
      return inputType
    }
    if let options, !options.isEmpty {
      return .choice
    }
    return .text
  }

  /// The resolved timeout in seconds.
  /// @param configTimeout The timeout from config.toml
  /// @returns Resolved timeout clamped to 1...3600
  func resolvedTimeout(configTimeout: Int) -> Int {
    let value = timeout ?? configTimeout
    return min(max(value, 1), 3600)
  }
}

/// Layout mode for multi-question dialogs.
enum QuestionMode: String, Codable {
  /// Step-by-step with forward/back navigation.
  case wizard
  /// All questions visible in collapsible sections.
  case accordion
}

/// A single question within a wizard/accordion dialog.
struct Question: Codable {
  /// Unique identifier for this question's answer.
  let id: String

  /// Display label for this question.
  let label: String

  /// The input type for this question.
  let type: DialogType

  /// Options for choice/multi-select questions.
  let options: [String]?

  /// Enable checkbox-style selection within this question.
  let multiSelect: Bool?

  /// Whether this question allows multiple selections.
  var isMultiSelect: Bool {
    multiSelect ?? false
  }
}
