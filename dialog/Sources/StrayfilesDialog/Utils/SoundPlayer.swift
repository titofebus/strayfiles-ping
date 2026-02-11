// SPDX-License-Identifier: MIT
import AppKit

/// Plays optional system sounds when dialogs appear.
/// Silent by default — only plays when configured.
enum SoundPlayer {

  /// Plays the configured dialog appearance sound.
  /// @param type The sound type from config
  static func playDialogSound(_ type: SoundType) {
    guard type != .none else { return }

    let soundName: NSSound.Name
    switch type {
    case .none:
      return
    case .subtle:
      soundName = NSSound.Name("Tink")
    case .pop:
      soundName = NSSound.Name("Pop")
    case .chime:
      soundName = NSSound.Name("Glass")
    }

    NSSound(named: soundName)?.play()
  }

  /// Plays the default system notification sound.
  /// Used for the `notify` input type with `sound: true`.
  static func playNotificationSound() {
    NSSound(named: NSSound.Name("Ping"))?.play()
  }
}
