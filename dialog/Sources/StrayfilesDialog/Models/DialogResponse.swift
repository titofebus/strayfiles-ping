import Foundation

/// JSON output model written to stdout when the dialog completes.
/// The Rust MCP server parses this to return to Claude.
struct DialogResponse: Codable {

  // MARK: - Standard response fields

  /// The user's answer. String for single values, [String] for multi-select,
  /// {id: value} for questions mode.
  var response: ResponseValue?

  /// Whether the notify type succeeded.
  var success: Bool?

  /// Whether the user cancelled (pressed Escape or closed the dialog).
  var cancelled: Bool?

  /// Whether the dialog was dismissed without a response.
  var dismissed: Bool?

  /// Optional freeform note from the user alongside their answer.
  var comment: String?

  // MARK: - Snooze fields

  /// Whether the user snoozed the dialog.
  var snoozed: Bool?

  /// The snooze duration in minutes.
  var snoozeMinutes: Int?

  /// Seconds until snooze expires (for agent retry logic).
  var retryAfterSeconds: Int?

  // MARK: - Feedback fields

  /// Whether the user provided feedback instead of answering.
  var feedback: Bool?

  /// The feedback text (redirect instruction for the agent).
  var feedbackText: String?

  // MARK: - Timeout fields

  /// Whether the dialog timed out.
  var timeout: Bool?

  /// Human-readable timeout message.
  var message: String?

  // MARK: - Questions fields

  /// Number of questions completed (for wizard/accordion mode).
  var completedCount: Int?

  // MARK: - Factory methods

  /// Creates a successful notification response.
  /// @returns Response with success: true
  static func notifySuccess() -> DialogResponse {
    DialogResponse(success: true)
  }

  /// Creates a cancellation response.
  /// @returns Response with cancelled and dismissed both true
  static func cancelled() -> DialogResponse {
    DialogResponse(cancelled: true, dismissed: true)
  }

  /// Creates a timeout response.
  /// @param seconds The timeout duration that elapsed
  /// @returns Response with timeout: true and a descriptive message
  static func timedOut(seconds: Int) -> DialogResponse {
    DialogResponse(
      timeout: true,
      message: "No response within \(seconds) seconds"
    )
  }

  /// Creates a snooze response.
  /// @param minutes The snooze duration in minutes
  /// @param retryAfterSeconds Seconds until snooze expires
  /// @returns Response with snooze fields populated
  static func snoozed(minutes: Int, retryAfterSeconds: Int) -> DialogResponse {
    DialogResponse(
      snoozed: true,
      snoozeMinutes: minutes,
      retryAfterSeconds: retryAfterSeconds
    )
  }

  /// Creates a feedback response.
  /// @param text The user's feedback/redirect text
  /// @returns Response with feedback fields populated
  static func feedbackResponse(text: String) -> DialogResponse {
    DialogResponse(
      feedback: true,
      feedbackText: text
    )
  }

  /// Creates a standard response with a single string value.
  /// @param value The user's answer
  /// @param comment Optional note alongside the answer
  /// @returns Standard response
  static func single(
    _ value: String, comment: String? = nil
  ) -> DialogResponse {
    DialogResponse(
      response: .string(value),
      cancelled: false,
      dismissed: false,
      comment: comment
    )
  }

  /// Creates a response with multiple selected values.
  /// @param values The selected options
  /// @param comment Optional note alongside the answer
  /// @returns Multi-select response
  static func multiple(
    _ values: [String], comment: String? = nil
  ) -> DialogResponse {
    DialogResponse(
      response: .array(values),
      cancelled: false,
      dismissed: false,
      comment: comment
    )
  }

  /// Creates a questions response with keyed answers.
  /// @param answers Dictionary mapping question id to answer
  /// @param completedCount Number of questions answered
  /// @param comment Optional note alongside the answer
  /// @returns Questions response
  static func questions(
    _ answers: [String: String],
    completedCount: Int,
    comment: String? = nil
  ) -> DialogResponse {
    DialogResponse(
      response: .dictionary(answers),
      cancelled: false,
      dismissed: false,
      comment: comment,
      completedCount: completedCount
    )
  }
}

/// A response value that can be a string, array, or dictionary.
/// Handles the polymorphic `response` field in the JSON output.
enum ResponseValue: Codable {
  case string(String)
  case array([String])
  case dictionary([String: String])

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .array(let values):
      try container.encode(values)
    case .dictionary(let dict):
      try container.encode(dict)
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let value = try? container.decode(String.self) {
      self = .string(value)
    } else if let values = try? container.decode([String].self) {
      self = .array(values)
    } else if let dict = try? container.decode([String: String].self) {
      self = .dictionary(dict)
    } else {
      throw DecodingError.typeMismatch(
        ResponseValue.self,
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Expected String, [String], or [String: String]"
        )
      )
    }
  }
}
