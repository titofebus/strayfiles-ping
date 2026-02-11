// SPDX-License-Identifier: MIT
import XCTest

@testable import strayfiles_dialog

final class InputPayloadTests: XCTestCase {

  /// Tests decoding a basic confirmation payload.
  func testDecodeConfirmation() throws {
    let json = """
      {
        "message": "Deploy to production?",
        "input_type": "confirmation"
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertEqual(payload.message, "Deploy to production?")
    XCTAssertEqual(payload.inputType, .confirmation)
    XCTAssertEqual(payload.resolvedType, .confirmation)
    XCTAssertNil(payload.title)
    XCTAssertNil(payload.options)
  }

  /// Tests decoding a choice payload with descriptions.
  func testDecodeChoice() throws {
    let json = """
      {
        "message": "Which strategy?",
        "input_type": "choice",
        "options": ["Blue-green", "Rolling", "Canary"],
        "descriptions": ["Zero-downtime", "Gradual", "Partial"],
        "default_selection": "Rolling"
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertEqual(payload.resolvedType, .choice)
    XCTAssertEqual(payload.options?.count, 3)
    XCTAssertEqual(payload.descriptions?.count, 3)
    XCTAssertEqual(payload.defaultSelection, "Rolling")
  }

  /// Tests decoding a questions payload.
  func testDecodeQuestions() throws {
    let json = """
      {
        "message": "Configure service",
        "input_type": "questions",
        "mode": "wizard",
        "questions": [
          {"id": "name", "label": "Service name", "type": "text"},
          {"id": "env", "label": "Environment", "type": "choice", "options": ["dev", "prod"]},
          {"id": "features", "label": "Features", "type": "choice", "options": ["logging", "metrics"], "multi_select": true}
        ]
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertEqual(payload.resolvedType, .questions)
    XCTAssertEqual(payload.mode, .wizard)
    XCTAssertEqual(payload.questions?.count, 3)
    XCTAssertEqual(payload.questions?[2].isMultiSelect, true)
    XCTAssertEqual(payload.questions?[0].isMultiSelect, false)
  }

  /// Tests resolved type falls back to choice when options exist.
  func testResolvedTypeWithOptions() throws {
    let json = """
      {
        "message": "Pick one",
        "options": ["A", "B", "C"]
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertNil(payload.inputType)
    XCTAssertEqual(payload.resolvedType, .choice)
  }

  /// Tests resolved type falls back to text when no options.
  func testResolvedTypeDefault() throws {
    let json = """
      {
        "message": "What should I do?"
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertEqual(payload.resolvedType, .text)
  }

  /// Tests timeout resolution with config fallback.
  func testResolvedTimeout() throws {
    let json = """
      {
        "message": "Test",
        "timeout": 120
      }
      """
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let payload = try decoder.decode(
      InputPayload.self, from: json.data(using: .utf8)!
    )

    XCTAssertEqual(payload.resolvedTimeout(configTimeout: 600), 120)

    let json2 = """
      {
        "message": "Test"
      }
      """
    let payload2 = try decoder.decode(
      InputPayload.self, from: json2.data(using: .utf8)!
    )

    XCTAssertEqual(payload2.resolvedTimeout(configTimeout: 600), 600)
  }
}
