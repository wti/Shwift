// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "Shwift",
  platforms: [
    .macOS(.v12)
  ],
  products: [
    .library(name: "Script", targets: ["Script"]),
    .library(name: "Shwift", targets: ["Shwift"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-system", from: "1.3.2"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.69.0"),
  ],
  targets: [
    .target(
      name: "Shwift",
      dependencies: [
        .product(name: "SystemPackage", package: "swift-system"),
        .product(name: "NIO", package: "swift-nio"),
        .product(name: "_NIOConcurrency", package: "swift-nio"),
      ],
      cSettings: [
        .define("_GNU_SOURCE", .when(platforms: [.linux]))
      ],
      swiftSettings: [.enableExperimentalFeature("AccessLevelOnImport")]),
    .target(
      name: "Script",
      dependencies: [
        "Shwift",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      swiftSettings: [.enableExperimentalFeature("AccessLevelOnImport")]),

    .executableTarget(
      name: "ScriptExample",
      dependencies: [
        "Script"
      ]
    ),
    .testTarget(
      name: "ShwiftTests",
      dependencies: ["Shwift"],
      resources: [
        .copy("Cat.txt")
      ]),
  ]
)
