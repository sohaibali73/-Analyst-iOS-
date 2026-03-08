// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AnalystApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "Analyst",
            targets: ["Analyst"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
        // .package(url: "https://github.com/...", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Analyst",
            dependencies: [],
            path: "Sources/Analyst",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
    ]
)
