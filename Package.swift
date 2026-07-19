// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LaunchNextCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "LaunchNextCore", targets: ["LaunchNextCore"])
    ],
    targets: [
        .target(
            name: "LaunchNextCore",
            path: "LaunchNext/AppKitFoundation"
        ),
        .testTarget(
            name: "LaunchNextCoreTests",
            dependencies: ["LaunchNextCore"],
            path: "LaunchNextCoreTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
