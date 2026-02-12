// SPDX-License-Identifier: MIT
import SwiftUI

/// Environment key for the dialog accent color.
private struct DialogAccentKey: EnvironmentKey {
  static let defaultValue = AccentResolver.defaultAccent
}

extension EnvironmentValues {
  /// The resolved accent color for the dialog.
  var dialogAccent: Color {
    get { self[DialogAccentKey.self] }
    set { self[DialogAccentKey.self] = newValue }
  }
}
