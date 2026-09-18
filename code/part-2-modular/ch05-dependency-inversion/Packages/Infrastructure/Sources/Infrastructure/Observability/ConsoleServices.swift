import Foundation
import os
import Domain

// Console implementations of the cross-cutting service contracts.
//
// These are the same dev/test stand-ins from Chapter 1, now living in
// Infrastructure where every concrete, outside-world detail belongs. They depend
// on `Domain` to conform to its protocols. `ConsoleLogger` is real local logging
// over Apple's unified logging; the other three are fakes of services we don't
// own and simply echo to the console. The real vendor adapters — a RemoteLogger,
// CrashlyticsReporter, AmplitudeAnalytics, a LaunchDarkly-backed flag provider —
// would sit right here beside them, selected by the composition root in Chapter
// 6. Swapping a vendor never leaves this folder.

/// Logs through Apple's unified logging. The production `RemoteLogger` that ships
/// logs to a backend would be its sibling here.
public struct ConsoleLogger: Domain.Logger { // `Domain.Logger`, not Apple's `os.Logger`
    private static let osLog = OSLog(subsystem: "com.playbook.iTunesSearchApp", category: "Infrastructure")

    public init() {}

    public func log(_ message: String) {
        os_log("%{public}@", log: Self.osLog, type: .debug, message)
    }
}

/// Prints analytics events instead of sending them to a backend.
public struct ConsoleAnalytics: AnalyticsTracker {
    public init() {}

    public func track(_ event: AnalyticsEvent) {
        print("📊 analytics: \(event.name) \(event.properties)")
    }
}

/// Prints crashes and breadcrumbs instead of uploading them.
public struct ConsoleCrashReporter: CrashReporter {
    public init() {}

    public func record(_ error: Error, context: [String: String]) {
        print("💥 crash: \(error) \(context)")
    }

    public func breadcrumb(_ message: String) {
        print("🍞 breadcrumb: \(message)")
    }
}

/// In-memory flags with optional overrides. Stands in for a real remote-config
/// service; later chapters drive the overrides from launch arguments so UI tests
/// can flip a flag deterministically.
public struct LocalFeatureFlags: FeatureFlagProvider {
    private let overrides: [FeatureFlag: Bool]

    public init(_ overrides: [FeatureFlag: Bool] = [:]) {
        self.overrides = overrides
    }

    public func isEnabled(_ flag: FeatureFlag) -> Bool {
        overrides[flag] ?? false
    }
}
