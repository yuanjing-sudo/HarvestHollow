// swift-tools-version: 5.9
// Harvest Hollow — a cozy 2D farm game written entirely in Swift.
//
// The package is split so that the simulation can run anywhere Swift runs
// (including Linux CI), while the SwiftUI presentation layer is only compiled
// on Apple platforms.

import PackageDescription

let package = Package(
    name: "HarvestHollow",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "HarvestHollowCore", targets: ["HarvestHollowCore"]),
        .library(name: "HarvestHollowUI", targets: ["HarvestHollowUI"]),
        .executable(name: "harvesthollow", targets: ["HarvestHollowCLI"])
    ],
    targets: [
        .target(
            name: "HarvestHollowCore",
            path: "Sources/HarvestHollowCore"
        ),
        .target(
            name: "HarvestHollowUI",
            dependencies: ["HarvestHollowCore"],
            path: "Sources/HarvestHollowUI"
        ),
        .executableTarget(
            name: "HarvestHollowCLI",
            dependencies: ["HarvestHollowCore"],
            path: "Sources/HarvestHollowCLI"
        ),
        .testTarget(
            name: "HarvestHollowCoreTests",
            dependencies: ["HarvestHollowCore"],
            path: "Tests/HarvestHollowCoreTests"
        )
    ]
)
