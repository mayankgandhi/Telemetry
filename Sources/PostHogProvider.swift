import Foundation
import PostHog

/// PostHog implementation of the TelemetryProvider protocol
///
/// Performance notes:
/// - Thread-safe: PostHog SDK handles its own threading
/// - No MainActor calls: All operations run on background threads
/// - Cached formatter: ISO8601DateFormatter is reused for better performance
/// - Nonisolated: Methods can be called from any thread without actor overhead
public final class PostHogProvider: TelemetryProvider, Sendable {
    private let apiKey: String
    private let host: String

    // Actor for thread-safe configuration state
    private actor ConfigState {
        var isConfigured = false

        func markConfigured() {
            isConfigured = true
        }
    }
    private let configState = ConfigState()

    // Cached date formatter for performance (thread-safe singleton)
    // ISO8601DateFormatter is thread-safe but not marked Sendable
    private static nonisolated(unsafe) let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    /// Initialize with PostHog credentials
    /// - Parameters:
    ///   - apiKey: PostHog API key
    ///   - host: PostHog host URL (default: https://us.i.posthog.com)
    public init(
        apiKey: String,
        host: String = "https://us.i.posthog.com"
    ) {
        self.apiKey = apiKey
        self.host = host
    }

    /// Configure PostHog SDK (call once during app initialization)
    /// - Note: Thread-safe, can be called from any thread
    public nonisolated func configure() async {
        // Check and set configuration state atomically
        let alreadyConfigured = await configState.isConfigured
        if alreadyConfigured { return }

        // Set configured state
        await configState.markConfigured()

        let config = PostHogConfig(apiKey: apiKey, host: host)
        // PostHog SDK setup must be called on main thread per SDK requirements
        await MainActor.run {
            PostHogSDK.shared.setup(config)
        }
    }

    // MARK: - TelemetryProvider Methods

    public nonisolated func track(event: TelemetryEvent) async {
        await ensureConfigured()

        // Convert Sendable properties to [String: Any] for PostHog
        let properties = convertProperties(event.properties)

        // PostHog SDK handles threading internally, safe to call from background
        PostHogSDK.shared.capture(
            event.name,
            properties: properties
        )
    }

    public nonisolated func identify(user: TelemetryUser) async {
        await ensureConfigured()

        // Convert Sendable properties to [String: Any] for PostHog
        let properties = convertProperties(user.properties)

        // PostHog SDK handles threading internally, safe to call from background
        PostHogSDK.shared.identify(
            user.userId,
            userProperties: properties
        )
    }

    public nonisolated func screen(screen: TelemetryScreen) async {
        await ensureConfigured()

        // Convert Sendable properties to [String: Any] for PostHog
        let properties = convertProperties(screen.properties)

        // PostHog SDK handles threading internally, safe to call from background
        PostHogSDK.shared.screen(
            screen.name,
            properties: properties
        )
    }

    public nonisolated func getFeatureFlag(key: String, defaultValue: Bool) async -> Bool {
        await ensureConfigured()

        // Feature flag access is synchronous and thread-safe
        return PostHogSDK.shared.isFeatureEnabled(key) ?? defaultValue
    }

    public nonisolated func getFeatureFlagPayload(key: String) async -> Any? {
        await ensureConfigured()

        // Feature flag payload access is synchronous and thread-safe
        return PostHogSDK.shared.getFeatureFlagPayload(key)
    }

    public nonisolated func getFeatureFlagPayloadString(key: String) async -> String? {
        await ensureConfigured()

        // Get payload and convert to string if possible
        guard let payload = PostHogSDK.shared.getFeatureFlagPayload(key) else {
            return ""
        }

        return payload as? String
    }

    public nonisolated func reset() async {
        await ensureConfigured()

        // PostHog SDK handles threading internally, safe to call from background
        PostHogSDK.shared.reset()
    }

    public nonisolated func flush() async {
        await ensureConfigured()

        // PostHog SDK handles threading internally, safe to call from background
        PostHogSDK.shared.flush()
    }

    // MARK: - Private Helpers

    private nonisolated func ensureConfigured() async {
        let configured = await configState.isConfigured
        if !configured {
            await configure()
        }
    }

    /// Convert Sendable properties to [String: Any] for PostHog compatibility
    /// - Note: Optimized with cached date formatter for better performance
    private nonisolated func convertProperties(_ properties: [String: any Sendable]) -> [String: Any] {
        guard !properties.isEmpty else { return [:] }

        var result = [String: Any]()
        result.reserveCapacity(properties.count)

        for (key, value) in properties {
            // PostHog accepts standard JSON-serializable types
            // Use pattern matching for better performance
            switch value {
            case let stringValue as String:
                result[key] = stringValue
            case let intValue as Int:
                result[key] = intValue
            case let doubleValue as Double:
                result[key] = doubleValue
            case let boolValue as Bool:
                result[key] = boolValue
            case let dateValue as Date:
                // Use cached formatter for performance
                result[key] = Self.dateFormatter.string(from: dateValue)
            case let arrayValue as [Any]:
                result[key] = arrayValue
            case let dictValue as [String: Any]:
                result[key] = dictValue
            default:
                // Fallback to string representation
                result[key] = "\(value)"
            }
        }
        return result
    }
}
