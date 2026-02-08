import AppKit

/// NSApplicationDelegate that manages the app lifecycle.
/// Runs as an accessory process (no dock icon, no menu bar).
final class DialogAppDelegate: NSObject, NSApplicationDelegate {

  /// Called when the application finishes launching.
  /// @param notification The launch notification
  func applicationDidFinishLaunching(_ notification: Notification) {
    // Bring window to front and activate
    NSApp.activate(ignoringOtherApps: true)
  }

  /// Terminates when the last window closes.
  /// @param sender The application
  /// @returns true to terminate when no windows remain
  func applicationShouldTerminateAfterLastWindowClosed(
    _ sender: NSApplication
  ) -> Bool {
    true
  }
}
