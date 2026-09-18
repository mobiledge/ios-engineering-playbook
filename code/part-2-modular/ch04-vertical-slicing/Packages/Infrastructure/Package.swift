// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Infrastructure", targets: ["Infrastructure"])
    ],
    dependencies: [
        // Infrastructure depends on Domain (to implement its protocols and
        // return its entities) — never the reverse.
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: ["Domain"]
        )
    ]
)
