// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Analyst",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .watchOS(.v10)
    ],
    products: [
        .executable(
            name: "Analyst",
            targets: ["Analyst"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
        // .package(url: "https://github.com/...", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Analyst",
            dependencies: [],
            path: "Sources/Analyst"
        ),
    ]
)
