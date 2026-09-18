import Foundation
import os

// MARK: - Cross-cutting service contracts (vendor-agnostic)
//
// Every app leans on a handful of services that aren't the product but keep it
// running: logging, crash reporting, analytics, and feature flags. We describe
// each as a plain protocol — what the app needs, with no mention of who provides
// it — so the vendor behind any one of them can change without touching feature
// code.
//
// MONOLITH NOTE: today these four contracts, their console implementations, AND
// the global that selects between them all live in the app target next to the
// features that call them. Nothing stops a view from importing a vendor SDK
// directly. Later chapters move the contracts to `Domain`, the implementations
// to `Infrastructure`, and the selection into a composition root.

/// Diagnostic logging. In dev it prints to the console; in production the same
/// calls can be routed to a log service. Choosing which is just a matter of
/// which implementation gets injected — see `Services` below.
protocol Logger {
    func log(_ message: String)
}

/// Crash and non-fatal error reporting.
protocol CrashReporter {
    func record(_ error: Error, context: [String: String])
    func breadcrumb(_ message: String)
}

/// Product analytics.
protocol AnalyticsTracker {
    func track(_ event: AnalyticsEvent)
}

/// Remote feature flags / remote configuration.
protocol FeatureFlagProvider {
    func isEnabled(_ flag: FeatureFlag) -> Bool
}

// MARK: - Typed payloads

struct AnalyticsEvent {
    let name: String
    let properties: [String: String]

    init(_ name: String, _ properties: [String: String] = [:]) {
        self.name = name
        self.properties = properties
    }
}

enum FeatureFlag: String {
    case newPodcastUI
    case offlineMode
}

// MARK: - Dev/test implementations
//
// The only implementations that exist in Chapter 1. `ConsoleLogger` is real
// local logging over Apple's unified logging; the other three are stand-ins for
// services we don't own yet — they just echo to the console. The app therefore
// runs end-to-end with zero vendor SDKs linked.

struct ConsoleLogger: Logger {
    private static let osLog = OSLog(subsystem: "com.playbook.iTunesSearchApp", category: "App")
    func log(_ message: String) {
        os_log("%{public}@", log: Self.osLog, type: .debug, message)
    }
}

struct ConsoleAnalytics: AnalyticsTracker {
    func track(_ event: AnalyticsEvent) {
        print("📊 analytics: \(event.name) \(event.properties)")
    }
}

struct ConsoleCrashReporter: CrashReporter {
    func record(_ error: Error, context: [String: String]) {
        print("💥 crash: \(error) \(context)")
    }
    func breadcrumb(_ message: String) {
        print("🍞 breadcrumb: \(message)")
    }
}

/// In-memory flags. Defaults live here for now; later chapters drive overrides
/// from launch arguments so UI tests can flip a flag deterministically.
struct LocalFeatureFlags: FeatureFlagProvider {
    private let overrides: [FeatureFlag: Bool]
    init(_ overrides: [FeatureFlag: Bool] = [:]) {
        self.overrides = overrides
    }
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        overrides[flag] ?? false
    }
}

// MARK: - The build-selected facade
//
// MONOLITH NOTE: a single global picks each implementation by build
// configuration. The `MOCK_SERVICES` flag is set for the Debug config in
// project.yml; Release would instead point at the real vendor adapters. This is
// the "policy" in one line per service — and the global we pay down in Chapter
// 6, when the choice moves into a composition root and these stop being globals.

enum Services {
    #if MOCK_SERVICES
    static let logger: Logger = ConsoleLogger()
    static let crashReporter: CrashReporter = ConsoleCrashReporter()
    static let analytics: AnalyticsTracker = ConsoleAnalytics()
    static let flags: FeatureFlagProvider = LocalFeatureFlags([.newPodcastUI: true])
    #else
    // Release build. Each line becomes a real vendor adapter in a later chapter
    // (RemoteLogger(), CrashlyticsReporter(), AmplitudeAnalytics(),
    // LaunchDarklyFlags()); for now the console versions keep the app runnable.
    static let logger: Logger = ConsoleLogger()
    static let crashReporter: CrashReporter = ConsoleCrashReporter()
    static let analytics: AnalyticsTracker = ConsoleAnalytics()
    static let flags: FeatureFlagProvider = LocalFeatureFlags()
    #endif
}
