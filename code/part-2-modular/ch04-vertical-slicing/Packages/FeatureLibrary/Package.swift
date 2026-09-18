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
        // The Infrastructure edge here is a deliberate flaw: this feature
        // package depends on the concrete Core Data layer directly, instead
        // of a protocol it doesn't own. Chapter 5 fixes it.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../Infrastructure")
    ],
    targets: [
        .target(
            name: "FeatureLibrary",
            dependencies: ["DesignSystem", "Domain", "Infrastructure"]
        )
    ]
)
