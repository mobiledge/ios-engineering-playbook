// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FeatureMovies",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "FeatureMovies", targets: ["FeatureMovies"])
    ],
    dependencies: [
        // Movies is born as a package, straight onto the Dependency Rule:
        // DesignSystem + Domain abstractions only, never Infrastructure.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "FeatureMovies",
            dependencies: ["DesignSystem", "Domain"]
        )
    ]
)
