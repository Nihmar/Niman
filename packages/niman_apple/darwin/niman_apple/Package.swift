// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "niman_apple",
  platforms: [
    .iOS("17.0"),
    .macOS("14.0"),
  ],
  products: [
    .library(name: "niman-apple", targets: ["niman_apple"])
  ],
  dependencies: [],
  targets: [
    .target(name: "niman_apple", dependencies: [])
  ]
)
