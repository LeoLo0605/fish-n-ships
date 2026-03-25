// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FishNShips",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "FishNShips",
            targets: ["FishNShips"]
        ),
    ],
    targets: [
        .target(
            name: "FishNShips",
            path: "FishNShips",
            resources: [
                .process("Assets.xcassets"),
            ],
            linkerSettings: [
                .linkedFramework("SpriteKit"),
            ]
        ),
        .testTarget(
            name: "FishNShipsTests",
            dependencies: ["FishNShips"],
            path: "FishNShipsTests"
        ),
    ]
)
