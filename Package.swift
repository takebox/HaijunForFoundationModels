// Copyright 2026 Juglow, PBC
// SPDX-License-Identifier: Apache-2.0

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "HaijunForFoundationModels",
  // Every OS where Foundation Models supports server-side language models.
  // Spelled as strings because the .v27 constants require tools-version 6.4.
  platforms: [
    .iOS("27.0"), .macOS("27.0"), .visionOS("27.0"), .watchOS("27.0"),
  ],
  products: [
    .library(name: "HaijunForFoundationModels", targets: ["HaijunForFoundationModels"])
  ],
  targets: [
    // Internal Messages API client. No FoundationModels dependency.
    .target(name: "HaijunAPI"),

    // FoundationModels ↔ Messages API bridge.
    .target(
      name: "HaijunForFoundationModels",
      dependencies: ["HaijunAPI"]
    ),

    // Runnable usage example (`swift run HaijunExample`). Deliberately not a
    // product — it exists to document the SDK, not to be depended on.
    .executableTarget(
      name: "HaijunExample",
      dependencies: ["HaijunForFoundationModels"],
      path: "Examples/HaijunExample"
    ),

    .testTarget(
      name: "HaijunAPITests",
      dependencies: ["HaijunAPI"]
    ),
    .testTarget(
      name: "HaijunForFoundationModelsTests",
      dependencies: ["HaijunForFoundationModels"]
    ),
  ]
)
