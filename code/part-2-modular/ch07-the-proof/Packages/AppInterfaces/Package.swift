// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AppInterfaces",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "AppInterfaces", targets: ["AppInterfaces"])
    ],
    dependencies: [
        // AppInterfaces depends on Domain only — it exists so features can
        // declare cross-feature navigation *needs* without importing the
        // feature that fulfills them.
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "AppInterfaces",
            dependencies: ["Domain"]
        )
    ]
)
