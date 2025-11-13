import Foundation

/// Represents an analytics event to be tracked
public struct TelemetryEvent: Sendable {
    /// The name of the event (e.g., "button_tapped", "screen_viewed")
    public let name: String

    /// Additional properties associated with the event
    public let properties: [String: any Sendable]

    /// Timestamp when the event occurred (defaults to now)
    public let timestamp: Date

    public init(
        name: String,
        properties: [String: any Sendable] = [:],
        timestamp: Date = Date()
    ) {
        self.name = name
        self.properties = properties
        self.timestamp = timestamp
    }
}
