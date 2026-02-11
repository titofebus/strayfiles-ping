// SPDX-License-Identifier: MIT
import AppKit

/// Calculates the window position on the primary screen.
/// Supports center, top-left, top-right, and bottom-right positions.
enum WindowPositioner {

  /// Edge padding from screen edges in points.
  private static let padding: CGFloat = 16

  /// Calculates the window origin for the given position and size.
  /// @param position The desired screen position
  /// @param windowSize The size of the window
  /// @returns The NSPoint origin for the window frame
  static func origin(
    for position: DialogPosition,
    windowSize: NSSize
  ) -> NSPoint {
    guard let screen = NSScreen.main else {
      return .zero
    }

    let visibleFrame = screen.visibleFrame

    switch position {
    case .center:
      return NSPoint(
        x: visibleFrame.midX - windowSize.width / 2,
        y: visibleFrame.midY - windowSize.height / 2
      )

    case .topLeft:
      return NSPoint(
        x: visibleFrame.minX + padding,
        y: visibleFrame.maxY - windowSize.height - padding
      )

    case .topRight:
      return NSPoint(
        x: visibleFrame.maxX - windowSize.width - padding,
        y: visibleFrame.maxY - windowSize.height - padding
      )

    case .bottomRight:
      return NSPoint(
        x: visibleFrame.maxX - windowSize.width - padding,
        y: visibleFrame.minY + padding
      )
    }
  }
}
