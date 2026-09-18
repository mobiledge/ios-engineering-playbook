// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "Domain", targets: ["Domain"])
    ],
    targets: [
        // The Domain layer depends on NOTHING. That isolation is the whole point:
        // it can be unit-tested in milliseconds with no network or database.
        .target(name: "Domain"),
        .testTarget(name: "DomainTests", dependencies: ["Domain"])
    ]
)
