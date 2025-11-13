import Foundation

/// Represents a screen view to be tracked
public struct TelemetryScreen: Sendable {
    /// The name of the screen (e.g., "HomeView", "SettingsView")
    public let name: String

    /// Additional properties associated with the screen view
    public let properties: [String: any Sendable]

    public init(
        name: String,
        properties: [String: any Sendable] = [:]
    ) {
        self.name = name
        self.properties = properties
    }
}
