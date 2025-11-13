import Foundation

/// Main telemetry service providing a simplified interface for analytics
/// Use `Telemetry.shared` to access the singleton instance
///
/// Performance notes:
/// - Fire-and-forget tracking methods use background tasks
/// - Thread-safe provider access using actor
/// - Zero overhead when provider is not configured
/// - Async methods available for compatibility with existing code
public final class TelemetryService: Sendable {
    /// Shared singleton instance
    public static let shared = TelemetryService()

    // Actor for thread-safe provider storage
    private actor ProviderStore {
        var provider: (any TelemetryProvider)?

        func setProvider(_ provider: any TelemetryProvider) {
            self.provider = provider
        }
    }
    private let providerStore = ProviderStore()

    internal init() {}

    // MARK: - Configuration

    /// Configure the telemetry service with a provider
    /// Call this once during app initialization
    /// - Parameter provider: The analytics provider to use (e.g., PostHogProvider)
    /// - Note: Thread-safe, can be called from any thread
    public func configure(provider: any TelemetryProvider) {
        // Set provider asynchronously - it will be available shortly after this call
        // For tests that need to wait, use configureAsync instead
        Task.detached(priority: .userInitiated) {
            await self.providerStore.setProvider(provider)
        }
    }
    
    /// Configure the telemetry service with a provider (async version that waits for completion)
    /// Use this in tests or when you need to ensure the provider is set before proceeding
    /// - Parameter provider: The analytics provider to use (e.g., PostHogProvider)
    internal func configureAsync(provider: any TelemetryProvider) async {
        await providerStore.setProvider(provider)
    }

    /// Get the current provider in a thread-safe way
    private func getProvider() async -> (any TelemetryProvider)? {
        await providerStore.provider
    }

    // MARK: - Event Tracking

    /// Track a custom event (fire-and-forget, non-blocking)
    /// - Parameters:
    ///   - event: Event name (e.g., "button_tapped")
    ///   - properties: Additional event properties
    /// - Note: Executes on background thread, returns immediately
    public func track(
        event: String,
        properties: [String: any Sendable] = [:]
    ) {
        let telemetryEvent = TelemetryEvent(
            name: event,
            properties: properties
        )

        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.track(event: telemetryEvent)
        }
    }

    /// Track a custom event with a TelemetryEvent model (fire-and-forget, non-blocking)
    /// - Parameter event: The event to track
    /// - Note: Executes on background thread, returns immediately
    public func track(event: TelemetryEvent) {
        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.track(event: event)
        }
    }

    /// Track a custom event (async version for compatibility)
    /// - Parameters:
    ///   - event: Event name
    ///   - properties: Additional event properties
    /// - Note: Use the non-async version for better performance
    public func trackAsync(
        event: String,
        properties: [String: any Sendable] = [:]
    ) async {
        guard let provider = await getProvider() else {
            logWarning("Provider not configured. Call configure(provider:) first.")
            return
        }

        let telemetryEvent = TelemetryEvent(
            name: event,
            properties: properties
        )
        await provider.track(event: telemetryEvent)
    }

    // MARK: - User Identification

    /// Identify a user with their unique ID and properties (fire-and-forget, non-blocking)
    /// - Parameters:
    ///   - userId: Unique user identifier
    ///   - properties: User properties (e.g., email, plan, signup_date)
    /// - Note: Executes on background thread, returns immediately
    public func identify(
        userId: String,
        properties: [String: any Sendable] = [:]
    ) {
        let user = TelemetryUser(
            userId: userId,
            properties: properties
        )

        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.identify(user: user)
        }
    }

    /// Identify a user with a TelemetryUser model (fire-and-forget, non-blocking)
    /// - Parameter user: The user to identify
    /// - Note: Executes on background thread, returns immediately
    public func identify(user: TelemetryUser) {
        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.identify(user: user)
        }
    }

    // MARK: - Screen Tracking

    /// Track a screen view (fire-and-forget, non-blocking)
    /// - Parameters:
    ///   - screen: Screen name (e.g., "HomeView", "SettingsView")
    ///   - properties: Additional screen properties
    /// - Note: Executes on background thread, returns immediately
    public func screen(
        screen: String,
        properties: [String: any Sendable] = [:]
    ) {
        let telemetryScreen = TelemetryScreen(
            name: screen,
            properties: properties
        )

        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.screen(screen: telemetryScreen)
        }
    }

    /// Track a screen view with a TelemetryScreen model (fire-and-forget, non-blocking)
    /// - Parameter screen: The screen to track
    /// - Note: Executes on background thread, returns immediately
    public func screen(screen: TelemetryScreen) {
        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.screen(screen: screen)
        }
    }

    // MARK: - Feature Flags

    /// Get a feature flag value (async, blocks until result is available)
    /// - Parameters:
    ///   - key: Feature flag key
    ///   - defaultValue: Default value if flag is not found
    /// - Returns: Feature flag value (true/false)
    /// - Note: This method blocks waiting for the result. Consider caching flag values for performance.
    public func getFeatureFlag(
        key: String,
        defaultValue: Bool = false
    ) async -> Bool {
        guard let provider = await getProvider() else {
            logWarning("Provider not configured. Call configure(provider:) first.")
            return defaultValue
        }

        return await provider.getFeatureFlag(
            key: key,
            defaultValue: defaultValue
        )
    }

    /// Get a feature flag payload value as a String (async, blocks until result is available)
    /// - Parameter key: Feature flag key
    /// - Returns: Feature flag payload value as String, or empty string if not found
    /// - Note: This method blocks waiting for the result. Consider caching payload values for performance.
    public func getFeatureFlagPayloadString(key: String) async -> String? {
        guard let provider = await getProvider() else {
            logWarning("Provider not configured. Call configure(provider:) first.")
            return ""
        }

        return await provider.getFeatureFlagPayloadString(key: key)
    }

    // MARK: - Session Management

    /// Reset the current user session (fire-and-forget, non-blocking)
    /// Call this when a user logs out
    /// - Note: Executes on background thread, returns immediately
    public func reset() {
        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.reset()
        }
    }

    /// Reset the current user session (async version, blocks until complete)
    /// Call this when a user logs out and you need to wait for completion
    public func resetAsync() async {
        guard let provider = await getProvider() else {
            logWarning("Provider not configured. Call configure(provider:) first.")
            return
        }

        await provider.reset()
    }

    /// Flush any pending events (fire-and-forget, non-blocking)
    /// Forces immediate sending of queued events
    /// - Note: Executes on background thread, returns immediately
    public func flush() {
        let providerStore = self.providerStore
        Task.detached(priority: .utility) {
            guard let provider = await providerStore.provider else {
                return
            }
            await provider.flush()
        }
    }

    /// Flush any pending events (async version, blocks until complete)
    /// Forces immediate sending of queued events and waits for completion
    /// - Note: Useful before app termination to ensure all events are sent
    public func flushAsync() async {
        guard let provider = await getProvider() else {
            logWarning("Provider not configured. Call configure(provider:) first.")
            return
        }

        await provider.flush()
    }

    // MARK: - Private Helpers

    private func logWarning(_ message: String) {
        #if DEBUG
        print("[Telemetry Warning] \(message)")
        #endif
    }
}

// MARK: - Convenience Extension

public extension TelemetryService {
    /// Convenience alias for the shared singleton
    static var `default`: TelemetryService { shared }
}
