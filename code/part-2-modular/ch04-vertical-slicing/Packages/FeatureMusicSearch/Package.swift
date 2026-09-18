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
        // The Infrastructure edge here is a deliberate flaw: this feature
        // package depends on the concrete networking layer directly, instead
        // of a protocol it doesn't own. Chapter 5 fixes it.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain"),
        .package(path: "../Infrastructure")
    ],
    targets: [
        .target(
            name: "FeatureMusicSearch",
            dependencies: ["DesignSystem", "Domain", "Infrastructure"]
        )
    ]
)
