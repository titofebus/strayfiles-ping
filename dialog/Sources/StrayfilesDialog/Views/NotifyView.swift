import AppKit
import UserNotifications

/// Sends a fire-and-forget macOS system notification.
/// No dialog, no waiting — just a banner notification.
enum NotifyView {

  /// Sends a macOS notification.
  /// Requests permission first, then sends the notification.
  /// @param message The notification body text
  /// @param title The optional notification title
  /// @param playSound Whether to play the system notification sound
  static func sendNotification(
    message: String,
    title: String?,
    playSound: Bool
  ) {
    let center = UNUserNotificationCenter.current()

    // Request authorization first, then send notification
    center.requestAuthorization(
      options: [.alert, .sound]
    ) { granted, _ in
      guard granted else {
        FileHandle.standardError.write(
          "Notification permission denied\n"
            .data(using: .utf8) ?? Data()
        )
        return
      }

      let content = UNMutableNotificationContent()
      content.body = message

      if let title, !title.isEmpty {
        content.title = title
      } else {
        content.title = "strayfiles-ping"
      }

      if playSound {
        content.sound = .default
      }

      let request = UNNotificationRequest(
        identifier: UUID().uuidString,
        content: content,
        trigger: nil
      )

      center.add(request) { error in
        if let error {
          FileHandle.standardError.write(
            "Notification error: \(error.localizedDescription)\n"
              .data(using: .utf8) ?? Data()
          )
        }
      }
    }
  }
}
