// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "StateModel",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "StateModel",
            targets: ["StateModel"]),
    ],
    targets: [
        .target(name: "StateModel"),
        .testTarget(
            name: "StateModelTests",
            dependencies: ["StateModel"]
        ),
    ],
    swiftLanguageModes: [.v5, .v6]
)
