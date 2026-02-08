import AppKit
import Foundation

/// Entry point for strayfiles-dialog CLI.
/// Parses arguments, reads config, and either shows a dialog
/// or writes a response immediately (snooze, version, error).
///
/// Usage:
///   strayfiles-dialog --json '{"message":"Deploy?","input_type":"confirmation"}'
///   echo '{"message":"..."}' | strayfiles-dialog --stdin
///   strayfiles-dialog --version

// MARK: - Argument parsing

/// Parses CLI arguments and returns the input payload JSON string.
/// Exits with version output or usage error as needed.
/// @returns JSON string from --json arg or --stdin
func parseArguments() -> String {
  let args = CommandLine.arguments

  if args.contains("--version") || args.contains("-v") {
    printToStdout("strayfiles-dialog 2.0.0")
    exit(0)
  }

  if let jsonIndex = args.firstIndex(of: "--json"),
    jsonIndex + 1 < args.count
  {
    return args[jsonIndex + 1]
  }

  if args.contains("--stdin") {
    var input = ""
    while let line = readLine(strippingNewline: false) {
      input += line
    }
    guard !input.isEmpty else {
      writeErrorAndExit("No input received on stdin")
    }
    return input
  }

  writeErrorAndExit(
    "Usage: strayfiles-dialog --json '{...}' | --stdin | --version"
  )
}

// MARK: - Output helpers

/// Writes a string to stdout (not stderr).
/// @param string The string to write
func printToStdout(_ string: String) {
  guard let data = (string + "\n").data(using: .utf8) else { return }
  FileHandle.standardOutput.write(data)
}

/// Writes a JSON error response to stdout and exits with code 1.
/// @param message The error description
func writeErrorAndExit(_ message: String) -> Never {
  let response: [String: Any] = [
    "error": message,
    "cancelled": true,
    "dismissed": true,
  ]
  if let data = try? JSONSerialization.data(
    withJSONObject: response, options: []),
    let json = String(data: data, encoding: .utf8)
  {
    printToStdout(json)
  }
  exit(1)
}

/// Writes a DialogResponse as JSON to stdout and exits with code 0.
/// @param response The dialog response to serialize
func writeResponseAndExit(_ response: DialogResponse) -> Never {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  if let data = try? encoder.encode(response),
    let json = String(data: data, encoding: .utf8)
  {
    printToStdout(json)
    exit(0)
  }
  writeErrorAndExit("Failed to encode response")
}

// MARK: - Signal handling

/// PID file path for singleton guard.
let pidFilePath = "/tmp/strayfiles-dialog.pid"

/// Cleans up PID file on process termination.
func cleanupPidFile() {
  try? FileManager.default.removeItem(atPath: pidFilePath)
}

// Handle SIGTERM and SIGINT for clean PID file removal
signal(SIGTERM) { _ in
  cleanupPidFile()
  exit(0)
}
signal(SIGINT) { _ in
  cleanupPidFile()
  exit(0)
}

// MARK: - Main

let jsonString = parseArguments()

// Decode input payload
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase

guard let jsonData = jsonString.data(using: .utf8),
  let payload = try? decoder.decode(InputPayload.self, from: jsonData)
else {
  writeErrorAndExit("Invalid JSON input")
}

// Read config
let config = ConfigReader.read()

// Check snooze state — if active, return snooze response immediately
if let snoozeUntil = config.snooze.until,
  snoozeUntil > Date()
{
  let remaining = Int(snoozeUntil.timeIntervalSinceNow)
  let response = DialogResponse.snoozed(
    minutes: remaining / 60,
    retryAfterSeconds: remaining
  )
  writeResponseAndExit(response)
}

// Check if local dialogs are enabled
if !config.dialog.enabled {
  writeErrorAndExit(
    "Local dialogs are disabled. Enable with: strayfiles-ping config set dialog.enabled true"
  )
}

// Handle notify type — fire-and-forget, no dialog
if payload.inputType == .notify {
  NotifyView.sendNotification(
    message: payload.message,
    title: payload.title,
    playSound: payload.sound ?? false
  )
  let response = DialogResponse.notifySuccess()
  writeResponseAndExit(response)
}

// Singleton guard — check pid file
if FileManager.default.fileExists(atPath: pidFilePath),
  let pidString = try? String(contentsOfFile: pidFilePath, encoding: .utf8),
  let existingPid = Int32(pidString.trimmingCharacters(in: .whitespacesAndNewlines)),
  kill(existingPid, 0) == 0
{
  writeErrorAndExit("Another dialog is already active")
}

// Write our pid
try? "\(ProcessInfo.processInfo.processIdentifier)"
  .write(toFile: pidFilePath, atomically: true, encoding: .utf8)

// Clean up pid file on exit
defer {
  cleanupPidFile()
}

// Launch the dialog app
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = DialogAppDelegate()
app.delegate = delegate

let coordinator = DialogCoordinator(
  payload: payload,
  config: config
)
coordinator.showDialog()
app.run()

// Response is written by DialogCoordinator when the dialog completes
