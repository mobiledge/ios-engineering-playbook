import Domain
import Infrastructure

// MARK: - The build-selected facade
//
// The four cross-cutting service contracts (`Logger`, `CrashReporter`,
// `AnalyticsTracker`, `FeatureFlagProvider`) and their typed payloads
// (`AnalyticsEvent`, `FeatureFlag`) used to live right here in the app target.
// This chapter moved them *inward*, to `Domain` — they describe what the app
// needs without saying who provides it. Their console implementations moved
// *outward*, to `Infrastructure` — the concrete, outside-world detail.
//
// `Services` itself thins down to just one job: picking which implementation
// wins, by build configuration. It still lives in the app target for now —
// that global selection is exactly what Chapter 6's composition root
// dissolves.

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
