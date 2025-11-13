import Foundation

/// Represents a user identity for analytics
public struct TelemetryUser: Sendable {
    /// Unique identifier for the user
    public let userId: String

    /// Additional properties associated with the user (e.g., email, plan, signup_date)
    public let properties: [String: any Sendable]

    public init(
        userId: String,
        properties: [String: any Sendable] = [:]
    ) {
        self.userId = userId
        self.properties = properties
    }
}
