// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioKitUI",
    platforms: [ .macOS(.v11), .iOS(.v14)],
    products: [.library(name: "AudioKitUI", targets: ["AudioKitUI"])],
    dependencies: [.package(url: "https://github.com/AudioKit/AudioKit.git", .branch("develop"))],
    targets: [
        .target(name: "AudioKitUI", dependencies: ["AudioKit"]),
        .testTarget(name: "AudioKitUITests", dependencies: ["AudioKitUI"]),
    ]
)
