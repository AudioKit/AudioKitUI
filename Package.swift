// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioKitUI",
    platforms: [.macOS(.v12), .iOS(.v15)],
    products: [.library(name: "AudioKitUI", targets: ["AudioKitUI"])],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.1"),
        .package(url: "https://github.com/AudioKit/Controls.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "AudioKitUI", dependencies: ["AudioKit", "Controls"], resources: [.process("Resources")]),
        .testTarget(name: "AudioKitUITests", dependencies: ["AudioKitUI"]),
    ]
)
