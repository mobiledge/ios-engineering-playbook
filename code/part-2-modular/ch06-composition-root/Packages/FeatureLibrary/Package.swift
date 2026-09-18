// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureLibrary",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FeatureLibrary", targets: ["FeatureLibrary"])
    ],
    dependencies: [
        // No Infrastructure: the Chapter 4 flaw is fixed. This feature depends
        // only on Domain's abstractions, plus AppInterfaces for the
        // LibraryRouter navigation abstraction — NOT for any concrete feature.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../AppInterfaces")
    ],
    targets: [
        .target(
            name: "FeatureLibrary",
            dependencies: ["DesignSystem", "Domain", "AppInterfaces"]
        )
    ]
)
