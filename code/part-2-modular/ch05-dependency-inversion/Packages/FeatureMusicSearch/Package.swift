// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureMusicSearch",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FeatureMusicSearch", targets: ["FeatureMusicSearch"])
    ],
    dependencies: [
        // No Infrastructure: the Chapter 4 flaw is fixed. This feature depends
        // only on Domain's abstractions — repositories and service contracts
        // are injected via the initializer instead.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "FeatureMusicSearch",
            dependencies: ["DesignSystem", "Domain"]
        )
    ]
)
