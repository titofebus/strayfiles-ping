// SPDX-License-Identifier: MIT
import AppKit

/// Handles global keyboard shortcuts for dialog navigation.
/// Installs an NSEvent local monitor for keyDown events.
final class KeyboardHandler {

  /// Callback types for keyboard events.
  typealias VoidAction = () -> Void

  private var monitor: Any?

  /// Actions triggered by global keyboard shortcuts.
  var onCancel: VoidAction?
  var onSnoozeToggle: VoidAction?
  var onFeedbackToggle: VoidAction?

  /// Installs the keyboard event monitor.
  /// Call this once when the dialog appears.
  func install() {
    monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      [weak self] event in
      self?.handleKeyEvent(event)
    }
  }

  /// Removes the keyboard event monitor.
  /// Call this when the dialog closes.
  func uninstall() {
    if let monitor {
      NSEvent.removeMonitor(monitor)
    }
    monitor = nil
  }

  deinit {
    uninstall()
  }

  // MARK: - Private

  /// Handles a key event and returns nil if consumed.
  /// @param event The key event to handle
  /// @returns nil if the event was consumed, the event otherwise
  private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
    // Only handle events without command modifier
    // (Cmd+C/V/X/A are handled by SwiftUI text fields natively)
    guard !event.modifierFlags.contains(.command) else {
      return event
    }

    switch event.keyCode {
    case KeyCode.escape:
      onCancel?()
      return nil

    case KeyCode.s:
      // Only toggle snooze if not in a text field
      if !isTextFieldFocused() {
        onSnoozeToggle?()
        return nil
      }

    case KeyCode.f:
      // Only toggle feedback if not in a text field
      if !isTextFieldFocused() {
        onFeedbackToggle?()
        return nil
      }

    default:
      break
    }

    return event
  }

  /// Checks if the current first responder is a text field.
  /// @returns true if a text editing view has focus
  private func isTextFieldFocused() -> Bool {
    guard let firstResponder = NSApp.keyWindow?.firstResponder else {
      return false
    }
    return firstResponder is NSTextView || firstResponder is NSTextField
  }
}

/// Keyboard key codes for readability.
private enum KeyCode {
  static let escape: UInt16 = 53
  static let returnKey: UInt16 = 36
  static let tab: UInt16 = 48
  static let space: UInt16 = 49
  static let upArrow: UInt16 = 126
  static let downArrow: UInt16 = 125
  static let leftArrow: UInt16 = 123
  static let rightArrow: UInt16 = 124
  static let s: UInt16 = 1
  static let f: UInt16 = 3
}
