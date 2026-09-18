import SwiftUI
import DesignSystem

/// A standalone catalog app for the design system.
///
/// It imports ONLY `DesignSystem` — no models, no networking, no database.
/// That means it compiles in a fraction of the time of the full app and lets
/// designers review every token and component in isolation. This is the payoff
/// the chapter promises from extracting the design system.
@main
struct CatalogApp: App {
    var body: some Scene {
        WindowGroup {
            CatalogView()
        }
    }
}
