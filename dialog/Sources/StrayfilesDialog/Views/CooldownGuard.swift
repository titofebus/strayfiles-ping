// SPDX-License-Identifier: MIT
import SwiftUI

/// Blocks keyboard input during the cooldown period after a dialog appears.
/// Off by default — only active when config.dialog.cooldown is true.
/// Shows a subtle progress indicator on the submit button.
struct CooldownGuard: ViewModifier {
  /// Whether cooldown is enabled.
  let isEnabled: Bool

  /// Cooldown duration in seconds.
  let duration: Double

  @Environment(\.dialogAccent) private var accent
  @State private var isCoolingDown = true

  func body(content: Content) -> some View {
    content
      .allowsHitTesting(!isCoolingDown || !isEnabled)
      .overlay(alignment: .bottom) {
        if isEnabled && isCoolingDown {
          GeometryReader { geometry in
            Rectangle()
              .fill(accent.opacity(0.3))
              .frame(height: 2)
              .frame(
                width: geometry.size.width,
                alignment: .leading
              )
          }
          .frame(height: 2)
        }
      }
      .accessibilityLabel(
        isEnabled && isCoolingDown
          ? "Input blocked during cooldown"
          : ""
      )
      .onAppear {
        guard isEnabled else {
          isCoolingDown = false
          return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          isCoolingDown = false
        }
      }
  }
}

extension View {
  /// Applies a cooldown guard to the view.
  /// @param isEnabled Whether cooldown is active
  /// @param duration Cooldown duration in seconds
  /// @returns The modified view
  func cooldownGuard(isEnabled: Bool, duration: Double) -> some View {
    modifier(CooldownGuard(isEnabled: isEnabled, duration: duration))
  }
}
