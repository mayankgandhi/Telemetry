import Testing
import Foundation
@testable import Telemetry

@Suite("TelemetryEvent Model Tests")
struct TelemetryEventTests {

    @Test("TelemetryEvent initializes with name only")
    func initializeWithNameOnly() {
        // Given & When
        let event = TelemetryEvent(name: "test_event")

        // Then
        #expect(event.name == "test_event")
        #expect(event.properties.isEmpty)
        #expect(event.timestamp != nil)
    }

    @Test("TelemetryEvent initializes with name and properties")
    func initializeWithNameAndProperties() {
        // Given
        let properties: [String: any Sendable] = [
            "key1": "value1",
            "key2": 42,
            "key3": true
        ]

        // When
        let event = TelemetryEvent(name: "test_event", properties: properties)

        // Then
        #expect(event.name == "test_event")
        #expect(event.properties.count == 3)
        #expect(event.properties["key1"] as? String == "value1")
        #expect(event.properties["key2"] as? Int == 42)
        #expect(event.properties["key3"] as? Bool == true)
    }

    @Test("TelemetryEvent initializes with custom timestamp")
    func initializeWithCustomTimestamp() {
        // Given
        let customDate = Date(timeIntervalSince1970: 1000000000)

        // When
        let event = TelemetryEvent(name: "test_event", timestamp: customDate)

        // Then
        #expect(event.name == "test_event")
        #expect(event.timestamp == customDate)
    }

    @Test("TelemetryEvent timestamp defaults to current time")
    func timestampDefaultsToCurrent() {
        // Given
        let before = Date()

        // When
        let event = TelemetryEvent(name: "test_event")

        // Then
        let after = Date()
        #expect(event.timestamp >= before)
        #expect(event.timestamp <= after)
    }

    @Test("TelemetryEvent supports various property types")
    func supportsVariousPropertyTypes() {
        // Given
        let date = Date()
        let properties: [String: any Sendable] = [
            "string": "text",
            "int": 123,
            "double": 3.14,
            "bool": true,
            "date": date,
            "array": [1, 2, 3],
            "dict": ["nested": "value"]
        ]

        // When
        let event = TelemetryEvent(name: "test_event", properties: properties)

        // Then
        #expect(event.properties["string"] as? String == "text")
        #expect(event.properties["int"] as? Int == 123)
        #expect(event.properties["double"] as? Double == 3.14)
        #expect(event.properties["bool"] as? Bool == true)
        #expect(event.properties["date"] as? Date == date)
        #expect((event.properties["array"] as? [Int])?.count == 3)
    }

    @Test("TelemetryEvent with empty properties")
    func initializeWithEmptyProperties() {
        // Given & When
        let event = TelemetryEvent(name: "test_event", properties: [:])

        // Then
        #expect(event.name == "test_event")
        #expect(event.properties.isEmpty)
    }
}

@Suite("TelemetryUser Model Tests")
struct TelemetryUserTests {

    @Test("TelemetryUser initializes with userId only")
    func initializeWithUserIdOnly() {
        // Given & When
        let user = TelemetryUser(userId: "user123")

        // Then
        #expect(user.userId == "user123")
        #expect(user.properties.isEmpty)
    }

    @Test("TelemetryUser initializes with userId and properties")
    func initializeWithUserIdAndProperties() {
        // Given
        let properties: [String: any Sendable] = [
            "email": "test@example.com",
            "plan": "premium",
            "age": 30
        ]

        // When
        let user = TelemetryUser(userId: "user123", properties: properties)

        // Then
        #expect(user.userId == "user123")
        #expect(user.properties.count == 3)
        #expect(user.properties["email"] as? String == "test@example.com")
        #expect(user.properties["plan"] as? String == "premium")
        #expect(user.properties["age"] as? Int == 30)
    }

    @Test("TelemetryUser supports various property types")
    func supportsVariousPropertyTypes() {
        // Given
        let signupDate = Date()
        let properties: [String: any Sendable] = [
            "email": "user@example.com",
            "isActive": true,
            "loginCount": 42,
            "balance": 99.99,
            "signupDate": signupDate,
            "tags": ["tag1", "tag2"],
            "metadata": ["key": "value"]
        ]

        // When
        let user = TelemetryUser(userId: "user456", properties: properties)

        // Then
        #expect(user.properties["email"] as? String == "user@example.com")
        #expect(user.properties["isActive"] as? Bool == true)
        #expect(user.properties["loginCount"] as? Int == 42)
        #expect(user.properties["balance"] as? Double == 99.99)
        #expect(user.properties["signupDate"] as? Date == signupDate)
        #expect((user.properties["tags"] as? [String])?.count == 2)
    }

    @Test("TelemetryUser with empty properties")
    func initializeWithEmptyProperties() {
        // Given & When
        let user = TelemetryUser(userId: "user789", properties: [:])

        // Then
        #expect(user.userId == "user789")
        #expect(user.properties.isEmpty)
    }

    @Test("TelemetryUser userId can be any string format")
    func userIdFormats() {
        // Test various userId formats
        let uuid = TelemetryUser(userId: "550e8400-e29b-41d4-a716-446655440000")
        let numeric = TelemetryUser(userId: "12345")
        let email = TelemetryUser(userId: "user@example.com")
        let custom = TelemetryUser(userId: "custom_user_id_123")

        #expect(uuid.userId == "550e8400-e29b-41d4-a716-446655440000")
        #expect(numeric.userId == "12345")
        #expect(email.userId == "user@example.com")
        #expect(custom.userId == "custom_user_id_123")
    }
}

@Suite("TelemetryScreen Model Tests")
struct TelemetryScreenTests {

    @Test("TelemetryScreen initializes with name only")
    func initializeWithNameOnly() {
        // Given & When
        let screen = TelemetryScreen(name: "HomeView")

        // Then
        #expect(screen.name == "HomeView")
        #expect(screen.properties.isEmpty)
    }

    @Test("TelemetryScreen initializes with name and properties")
    func initializeWithNameAndProperties() {
        // Given
        let properties: [String: any Sendable] = [
            "section": "main",
            "tab": "home",
            "isFirstVisit": true
        ]

        // When
        let screen = TelemetryScreen(name: "HomeView", properties: properties)

        // Then
        #expect(screen.name == "HomeView")
        #expect(screen.properties.count == 3)
        #expect(screen.properties["section"] as? String == "main")
        #expect(screen.properties["tab"] as? String == "home")
        #expect(screen.properties["isFirstVisit"] as? Bool == true)
    }

    @Test("TelemetryScreen supports various property types")
    func supportsVariousPropertyTypes() {
        // Given
        let loadTime = Date()
        let properties: [String: any Sendable] = [
            "screenName": "SettingsView",
            "loadTimeMs": 150,
            "isModal": false,
            "previousScreen": "HomeView",
            "loadTime": loadTime,
            "params": ["id": "123", "mode": "edit"]
        ]

        // When
        let screen = TelemetryScreen(name: "SettingsView", properties: properties)

        // Then
        #expect(screen.properties["screenName"] as? String == "SettingsView")
        #expect(screen.properties["loadTimeMs"] as? Int == 150)
        #expect(screen.properties["isModal"] as? Bool == false)
        #expect(screen.properties["previousScreen"] as? String == "HomeView")
        #expect(screen.properties["loadTime"] as? Date == loadTime)
    }

    @Test("TelemetryScreen with empty properties")
    func initializeWithEmptyProperties() {
        // Given & When
        let screen = TelemetryScreen(name: "ProfileView", properties: [:])

        // Then
        #expect(screen.name == "ProfileView")
        #expect(screen.properties.isEmpty)
    }

    @Test("TelemetryScreen name can be any string format")
    func screenNameFormats() {
        // Test various screen name formats
        let camelCase = TelemetryScreen(name: "HomeView")
        let snakeCase = TelemetryScreen(name: "home_view")
        let kebabCase = TelemetryScreen(name: "home-view")
        let withPath = TelemetryScreen(name: "/settings/profile")

        #expect(camelCase.name == "HomeView")
        #expect(snakeCase.name == "home_view")
        #expect(kebabCase.name == "home-view")
        #expect(withPath.name == "/settings/profile")
    }
}

@Suite("Model Sendable Conformance Tests")
struct ModelSendableTests {

    @Test("TelemetryEvent is Sendable and thread-safe")
    func telemetryEventIsSendable() async {
        // Given
        let event = TelemetryEvent(name: "test_event", properties: ["key": "value"])

        // When - Pass to async context
        let eventName = await Task {
            event.name
        }.value

        // Then
        #expect(eventName == "test_event")
    }

    @Test("TelemetryUser is Sendable and thread-safe")
    func telemetryUserIsSendable() async {
        // Given
        let user = TelemetryUser(userId: "user123", properties: ["email": "test@example.com"])

        // When - Pass to async context
        let userId = await Task {
            user.userId
        }.value

        // Then
        #expect(userId == "user123")
    }

    @Test("TelemetryScreen is Sendable and thread-safe")
    func telemetryScreenIsSendable() async {
        // Given
        let screen = TelemetryScreen(name: "HomeView", properties: ["section": "main"])

        // When - Pass to async context
        let screenName = await Task {
            screen.name
        }.value

        // Then
        #expect(screenName == "HomeView")
    }
}
