// SPDX-License-Identifier: MIT
import AppKit
import SwiftUI

/// Coordinates dialog window creation, positioning, and lifecycle.
/// Creates the borderless window, sets up the SwiftUI content,
/// and handles the response when the dialog completes.
final class DialogCoordinator {

  private let payload: InputPayload
  private let config: DialogConfig
  private var window: BorderlessWindow?
  private var timeoutTimer: Timer?

  /// Creates a coordinator for the given input payload and config.
  /// @param payload The dialog input from the Rust MCP server
  /// @param config The parsed config.toml settings
  init(payload: InputPayload, config: DialogConfig) {
    self.payload = payload
    self.config = config
  }

  /// Shows the dialog window and starts the timeout timer.
  func showDialog() {
    let window = BorderlessWindow(
      position: config.dialog.position,
      alwaysOnTop: config.dialog.alwaysOnTop
    )

    let timeoutSeconds = payload.resolvedTimeout(
      configTimeout: config.dialog.timeout
    )

    // Create the SwiftUI content
    let contentView = DialogContainer(
      payload: payload,
      config: config,
      onComplete: { [weak self] response in
        self?.handleResponse(response)
      }
    )

    // Wrap in hosting view
    let hostingView = NSHostingView(rootView: contentView)
    hostingView.translatesAutoresizingMaskIntoConstraints = false

    // Set up vibrancy background
    let vibrancy = VibrancyView(
      frame: NSRect(x: 0, y: 0, width: 400, height: 200)
    )
    vibrancy.translatesAutoresizingMaskIntoConstraints = false
    vibrancy.addSubview(hostingView)

    NSLayoutConstraint.activate([
      hostingView.topAnchor.constraint(equalTo: vibrancy.topAnchor),
      hostingView.bottomAnchor.constraint(equalTo: vibrancy.bottomAnchor),
      hostingView.leadingAnchor.constraint(equalTo: vibrancy.leadingAnchor),
      hostingView.trailingAnchor.constraint(equalTo: vibrancy.trailingAnchor),
    ])

    window.contentView = vibrancy

    // Size to content
    let fittingSize = hostingView.fittingSize
    let windowSize = NSSize(
      width: max(fittingSize.width, 300),
      height: fittingSize.height
    )
    window.setContentSize(windowSize)

    // Position on screen
    let origin = WindowPositioner.origin(
      for: config.dialog.position,
      windowSize: windowSize
    )
    window.setFrameOrigin(origin)

    // Play sound if configured
    SoundPlayer.playDialogSound(config.dialog.sound)

    // Show window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    self.window = window

    // Start timeout timer
    startTimeout(seconds: timeoutSeconds)
  }

  // MARK: - Private

  /// Starts the auto-dismiss timeout timer.
  /// @param seconds Seconds until timeout
  private func startTimeout(seconds: Int) {
    timeoutTimer = Timer.scheduledTimer(
      withTimeInterval: TimeInterval(seconds),
      repeats: false
    ) { [weak self] _ in
      let response = DialogResponse.timedOut(seconds: seconds)
      self?.handleResponse(response)
    }
  }

  /// Handles the dialog response — writes JSON to stdout and exits.
  /// @param response The dialog response to write
  private func handleResponse(_ response: DialogResponse) {
    timeoutTimer?.invalidate()
    window?.close()
    writeResponseAndExit(response)
  }
}
