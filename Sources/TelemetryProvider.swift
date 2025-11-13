import Foundation

/// Protocol defining the analytics provider interface
/// Implement this protocol to add support for different analytics services
public protocol TelemetryProvider: Sendable {
    /// Track a custom event
    /// - Parameter event: The event to track
    func track(event: TelemetryEvent) async

    /// Identify a user with their properties
    /// - Parameter user: The user to identify
    func identify(user: TelemetryUser) async

    /// Track a screen view
    /// - Parameter screen: The screen to track
    func screen(screen: TelemetryScreen) async

    /// Get a feature flag value
    /// - Parameters:
    ///   - key: The feature flag key
    ///   - defaultValue: The default value if the flag is not found
    /// - Returns: The feature flag value (true/false)
    func getFeatureFlag(key: String, defaultValue: Bool) async -> Bool

    /// Get a feature flag payload value as a String
    /// - Parameter key: The feature flag key
    /// - Returns: The payload value as a String, or empty string if not found
    func getFeatureFlagPayloadString(key: String) async -> String?

    /// Reset the current user session
    /// Useful for logout scenarios
    func reset() async

    /// Flush any pending events
    /// Forces immediate sending of queued events
    func flush() async
}
