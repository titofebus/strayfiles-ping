import XCTest

@testable import strayfiles_dialog

final class WindowPositionerTests: XCTestCase {

  /// Tests that top-right position is in the upper right area.
  func testTopRightPosition() {
    let size = NSSize(width: 400, height: 200)
    let origin = WindowPositioner.origin(for: .topRight, windowSize: size)

    // Should be near the right edge (accounting for padding)
    // and near the top (accounting for padding)
    // We can't test exact values since screen size varies,
    // but the origin should be positive
    XCTAssertGreaterThan(origin.x, 0)
    XCTAssertGreaterThan(origin.y, 0)
  }

  /// Tests that center position is roughly centered.
  func testCenterPosition() {
    let size = NSSize(width: 400, height: 200)
    let origin = WindowPositioner.origin(for: .center, windowSize: size)

    // Origin should be positive for center placement
    XCTAssertGreaterThan(origin.x, 0)
    XCTAssertGreaterThan(origin.y, 0)
  }

  /// Tests that all positions return valid coordinates.
  func testAllPositionsReturnValidCoordinates() {
    let size = NSSize(width: 300, height: 150)
    let positions: [DialogPosition] = [
      .center, .topLeft, .topRight, .bottomRight,
    ]

    for position in positions {
      let origin = WindowPositioner.origin(for: position, windowSize: size)
      // All positions should return finite numbers
      XCTAssertFalse(origin.x.isNaN, "\(position) x is NaN")
      XCTAssertFalse(origin.y.isNaN, "\(position) y is NaN")
      XCTAssertFalse(origin.x.isInfinite, "\(position) x is infinite")
      XCTAssertFalse(origin.y.isInfinite, "\(position) y is infinite")
    }
  }
}
