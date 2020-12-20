// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AudioKitUI",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v11)
    ],
    products: [
        .library(
            name: "AudioKitUI",
            targets: ["AudioKitUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", .branch("v5-develop"))
    ],
    targets: [
        .target(
            name: "AudioKitUI",
            dependencies: ["AudioKit"]),
        .testTarget(
            name: "AudioKitUITests",
            dependencies: ["AudioKitUI"]),
    ]
)
