// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "yjump",
  platforms: [
    .macOS(.v11)
  ],
  products: [
    .executable(name: "yjump", targets: ["yjump"])
  ],
  dependencies: [],
  targets: [
    .executableTarget(
      name: "yjump",
      dependencies: [],
      path: "src",
      sources: ["cli.swift", "conf.swift", "gui.swift", "main.swift"],
      linkerSettings: [
        .linkedFramework("Cocoa"),
        .linkedFramework("ApplicationServices"),
      ]
    )
  ]
)
