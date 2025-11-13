import Foundation

/// Mock implementation of TelemetryProvider for testing and SwiftUI previews
/// Records all events, users, and screens for verification
public actor MockTelemetryProvider: TelemetryProvider {
    /// All tracked events
    public private(set) var trackedEvents: [TelemetryEvent] = []

    /// All identified users
    public private(set) var identifiedUsers: [TelemetryUser] = []

    /// All tracked screens
    public private(set) var trackedScreens: [TelemetryScreen] = []

    /// Feature flag values to return
    public var featureFlags: [String: Bool] = [:]

    /// Feature flag payload values to return
    public var featureFlagPayloads: [String: Any] = [:]

    /// Number of times reset was called
    public private(set) var resetCallCount = 0

    /// Number of times flush was called
    public private(set) var flushCallCount = 0

    public init() {}

    // MARK: - TelemetryProvider Methods

    public func track(event: TelemetryEvent) async {
        trackedEvents.append(event)
    }

    public func identify(user: TelemetryUser) async {
        identifiedUsers.append(user)
    }

    public func screen(screen: TelemetryScreen) async {
        trackedScreens.append(screen)
    }

    public func getFeatureFlag(key: String, defaultValue: Bool) async -> Bool {
        return featureFlags[key] ?? defaultValue
    }

    public func getFeatureFlagPayloadString(key: String) async -> String? {
        guard let payload = featureFlagPayloads[key] else {
            return ""
        }
        return payload as? String ?? ""
    }

    public func reset() async {
        trackedEvents.removeAll()
        identifiedUsers.removeAll()
        trackedScreens.removeAll()
        resetCallCount += 1
    }

    public func flush() async {
        flushCallCount += 1
    }

    // MARK: - Test Helpers

    /// Set a feature flag value (useful for testing)
    public func setFeatureFlag(_ value: Bool, forKey key: String) {
        featureFlags[key] = value
    }

    /// Set a feature flag payload value (useful for testing)
    public func setFeatureFlagPayload(_ value: Any, forKey key: String) {
        featureFlagPayloads[key] = value
    }

    /// Clear all recorded data (useful between tests)
    public func clearAll() {
        trackedEvents.removeAll()
        identifiedUsers.removeAll()
        trackedScreens.removeAll()
        featureFlags.removeAll()
        featureFlagPayloads.removeAll()
        resetCallCount = 0
        flushCallCount = 0
    }

    /// Check if a specific event was tracked
    /// - Parameter eventName: The event name to search for
    /// - Returns: True if the event was tracked
    public func didTrack(eventName: String) -> Bool {
        trackedEvents.contains { $0.name == eventName }
    }

    /// Get the last tracked event
    public var lastEvent: TelemetryEvent? {
        trackedEvents.last
    }

    /// Get the last identified user
    public var lastUser: TelemetryUser? {
        identifiedUsers.last
    }

    /// Get the last tracked screen
    public var lastScreen: TelemetryScreen? {
        trackedScreens.last
    }
}
