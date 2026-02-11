// SPDX-License-Identifier: MIT
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "StrayfilesDialog",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: "strayfiles-dialog",
      path: "Sources/StrayfilesDialog"
    ),
    .testTarget(
      name: "StrayfilesDialogTests",
      dependencies: [
        .target(name: "strayfiles-dialog")
      ],
      path: "Tests/StrayfilesDialogTests"
    ),
  ]
)
