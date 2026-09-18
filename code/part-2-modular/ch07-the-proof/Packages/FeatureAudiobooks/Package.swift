// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureAudiobooks",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FeatureAudiobooks", targets: ["FeatureAudiobooks"])
    ],
    dependencies: [
        // Built straight from the template this chapter codifies: Domain's
        // abstractions plus AppInterfaces, never Infrastructure. Same recipe
        // as every feature package since Chapter 5 — one dev, one day.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../AppInterfaces")
    ],
    targets: [
        .target(
            name: "FeatureAudiobooks",
            dependencies: ["DesignSystem", "Domain", "AppInterfaces"]
        )
    ]
)
