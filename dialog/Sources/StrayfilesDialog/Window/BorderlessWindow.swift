import AppKit
import SwiftUI

/// Borderless floating NSWindow for dialog rendering.
/// No title bar, no chrome — content only. Draggable by background.
final class BorderlessWindow: NSWindow {

  /// Creates a borderless floating window.
  /// @param position The screen position for the window
  /// @param alwaysOnTop Whether the window floats above all others
  init(position: DialogPosition, alwaysOnTop: Bool) {
    super.init(
      contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )

    isMovableByWindowBackground = true
    backgroundColor = .clear
    isOpaque = false
    hasShadow = true
    level = alwaysOnTop ? .floating : .normal

    // No animation on appearance
    animationBehavior = .none
  }

  /// Updates the window size to fit its content and repositions
  /// so the top edge stays anchored.
  /// @param size The new content size
  func updateContentSize(_ size: NSSize) {
    let currentTop = frame.origin.y + frame.size.height
    let newOrigin = NSPoint(
      x: frame.origin.x,
      y: currentTop - size.height
    )
    setFrame(
      NSRect(origin: newOrigin, size: size),
      display: true,
      animate: false
    )
  }

  // Allow first responder for keyboard events
  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }
}

/// NSVisualEffectView wrapper for vibrancy background.
/// Provides the native macOS frosted glass appearance.
final class VibrancyView: NSVisualEffectView {

  /// Creates a vibrancy view with system material.
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    material = .hudWindow
    blendingMode = .behindWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 10
    layer?.masksToBounds = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) not supported")
  }
}
