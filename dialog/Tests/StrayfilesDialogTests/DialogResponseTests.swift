import XCTest

@testable import strayfiles_dialog

final class DialogResponseTests: XCTestCase {

  private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }()

  /// Tests encoding a notify success response.
  func testNotifyResponse() throws {
    let response = DialogResponse.notifySuccess()
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["success"] as? Bool, true)
    XCTAssertNil(json?["response"])
  }

  /// Tests encoding a cancelled response.
  func testCancelledResponse() throws {
    let response = DialogResponse.cancelled()
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["cancelled"] as? Bool, true)
    XCTAssertEqual(json?["dismissed"] as? Bool, true)
  }

  /// Tests encoding a timeout response.
  func testTimeoutResponse() throws {
    let response = DialogResponse.timedOut(seconds: 300)
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["timeout"] as? Bool, true)
    XCTAssertEqual(
      json?["message"] as? String, "No response within 300 seconds"
    )
  }

  /// Tests encoding a snooze response.
  func testSnoozeResponse() throws {
    let response = DialogResponse.snoozed(
      minutes: 15, retryAfterSeconds: 900
    )
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["snoozed"] as? Bool, true)
    XCTAssertEqual(json?["snooze_minutes"] as? Int, 15)
    XCTAssertEqual(json?["retry_after_seconds"] as? Int, 900)
  }

  /// Tests encoding a feedback response.
  func testFeedbackResponse() throws {
    let response = DialogResponse.feedbackResponse(
      text: "Skip this, focus on tests"
    )
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["feedback"] as? Bool, true)
    XCTAssertEqual(
      json?["feedback_text"] as? String, "Skip this, focus on tests"
    )
  }

  /// Tests encoding a single string response with comment.
  func testSingleResponse() throws {
    let response = DialogResponse.single(
      "Deploy", comment: "skip migration"
    )
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["response"] as? String, "Deploy")
    XCTAssertEqual(json?["cancelled"] as? Bool, false)
    XCTAssertEqual(json?["dismissed"] as? Bool, false)
    XCTAssertEqual(json?["comment"] as? String, "skip migration")
  }

  /// Tests encoding a multi-select response.
  func testMultipleResponse() throws {
    let response = DialogResponse.multiple(["react", "next"])
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(json?["response"] as? [String], ["react", "next"])
  }

  /// Tests encoding a questions response.
  func testQuestionsResponse() throws {
    let response = DialogResponse.questions(
      ["name": "auth-api", "env": "staging"],
      completedCount: 2
    )
    let data = try encoder.encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    let answers = json?["response"] as? [String: String]
    XCTAssertEqual(answers?["name"], "auth-api")
    XCTAssertEqual(answers?["env"], "staging")
    XCTAssertEqual(json?["completed_count"] as? Int, 2)
  }

  /// Tests ResponseValue round-trip encoding/decoding.
  func testResponseValueRoundTrip() throws {
    let decoder = JSONDecoder()

    // String
    let stringData = try encoder.encode(ResponseValue.string("hello"))
    let decodedString = try decoder.decode(ResponseValue.self, from: stringData)
    if case .string(let value) = decodedString {
      XCTAssertEqual(value, "hello")
    } else {
      XCTFail("Expected string")
    }

    // Array
    let arrayData = try encoder.encode(ResponseValue.array(["a", "b"]))
    let decodedArray = try decoder.decode(ResponseValue.self, from: arrayData)
    if case .array(let values) = decodedArray {
      XCTAssertEqual(values, ["a", "b"])
    } else {
      XCTFail("Expected array")
    }

    // Dictionary
    let dictData = try encoder.encode(
      ResponseValue.dictionary(["k": "v"])
    )
    let decodedDict = try decoder.decode(ResponseValue.self, from: dictData)
    if case .dictionary(let dict) = decodedDict {
      XCTAssertEqual(dict["k"], "v")
    } else {
      XCTFail("Expected dictionary")
    }
  }
}
