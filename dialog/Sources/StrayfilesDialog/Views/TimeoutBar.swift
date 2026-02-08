import SwiftUI

/// Thin progress bar showing remaining time before auto-dismiss.
/// Positioned at the top of the dialog.
struct TimeoutBar: View {
  /// Total timeout duration in seconds.
  let totalSeconds: Int

  /// The start date of the dialog.
  let startDate: Date

  @State private var progress: Double = 1.0
  @State private var countdownTimer: Timer?

  var body: some View {
    GeometryReader { geometry in
      Rectangle()
        .fill(Color.accentColor.opacity(0.4))
        .frame(
          width: geometry.size.width * progress,
          height: 2
        )
    }
    .frame(height: 2)
    .accessibilityLabel("Time remaining")
    .accessibilityValue(
      "\(Int(progress * Double(totalSeconds))) seconds remaining"
    )
    .onAppear {
      startCountdown()
    }
    .onDisappear {
      countdownTimer?.invalidate()
      countdownTimer = nil
    }
  }

  /// Starts the countdown animation using a timer.
  private func startCountdown() {
    countdownTimer = Timer.scheduledTimer(
      withTimeInterval: 1.0,
      repeats: true
    ) { timer in
      let elapsed = Date().timeIntervalSince(startDate)
      let remaining = Double(totalSeconds) - elapsed
      progress = max(0, remaining / Double(totalSeconds))
      if remaining <= 0 {
        timer.invalidate()
      }
    }
  }
}
