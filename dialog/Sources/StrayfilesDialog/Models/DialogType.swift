// SPDX-License-Identifier: MIT
import Foundation

/// All supported dialog input types.
/// Maps directly to the `input_type` field in the JSON payload.
enum DialogType: String, Codable {
  case notify
  case confirmation
  case choice
  case multiSelect = "multi_select"
  case text
  case secureText = "secure_text"
  case questions
}
