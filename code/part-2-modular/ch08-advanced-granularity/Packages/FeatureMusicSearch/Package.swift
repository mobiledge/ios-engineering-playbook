// swift-tools-version: 5.9
import PackageDescription

// Chapter 8: Music Search is the one feature under enough internal collision
// pressure to earn a second round of slicing — this time *within* the
// package, not across it. Three targets, three products:
//
//   MusicSearchInterface — the contract (`MusicSearchViewModeling` + Domain
//   types). No SwiftUI, no business logic.
//   MusicSearchLogic     — `MusicSearchViewModel`. Conforms to the
//   interface, depends on Domain's use cases. Must NOT import SwiftUI.
//   MusicSearchUI        — `MusicSearchScreen` + `TrackRow`. Pure SwiftUI,
//   generic over the interface.
//
// UI and Logic both depend on Interface — never on each other. The app
// target links UI + Logic and the composition root (`AppFactory`) wires the
// Logic-built view model into the UI-built screen.
let package = Package(
    name: "FeatureMusicSearch",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "MusicSearchInterface", targets: ["MusicSearchInterface"]),
        .library(name: "MusicSearchLogic", targets: ["MusicSearchLogic"]),
        .library(name: "MusicSearchUI", targets: ["MusicSearchUI"])
    ],
    dependencies: [
        // No Infrastructure — same rule as every other feature since Chapter 5.
        .package(path: "../DesignSystem"),
        .package(path: "../Domain")
    ],
    targets: [
        // Protocols + the feature's public contract. No SwiftUI, no logic.
        .target(
            name: "MusicSearchInterface",
            dependencies: ["Domain"]
        ),
        // ViewModel only. Depends on Interface + Domain's use cases and
        // service contracts. No SwiftUI import — enforced by this target's
        // dependency list, not just convention.
        .target(
            name: "MusicSearchLogic",
            dependencies: ["MusicSearchInterface", "Domain"]
        ),
        // Views only. Generic over MusicSearchViewModeling, so it compiles
        // and previews without ever linking MusicSearchLogic.
        .target(
            name: "MusicSearchUI",
            dependencies: ["MusicSearchInterface", "DesignSystem", "Domain"]
        )
    ]
)
