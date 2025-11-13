import Testing
import Foundation
@testable import Telemetry

@Suite("MockTelemetryProvider Tests")
struct MockTelemetryProviderTests {

    @Test("Mock provider tracks events correctly")
    func trackEvent() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let event = TelemetryEvent(name: "test_event", properties: ["key": "value"])

        // When
        await mockProvider.track(event: event)

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1)
        #expect(trackedEvents.first?.name == "test_event")
        #expect(trackedEvents.first?.properties["key"] as? String == "value")
    }

    @Test("Mock provider tracks multiple events in order")
    func trackMultipleEvents() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let event1 = TelemetryEvent(name: "event1")
        let event2 = TelemetryEvent(name: "event2")
        let event3 = TelemetryEvent(name: "event3")

        // When
        await mockProvider.track(event: event1)
        await mockProvider.track(event: event2)
        await mockProvider.track(event: event3)

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 3)
        #expect(trackedEvents[0].name == "event1")
        #expect(trackedEvents[1].name == "event2")
        #expect(trackedEvents[2].name == "event3")
    }

    @Test("Mock provider identifies users correctly")
    func identifyUser() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let user = TelemetryUser(userId: "user123", properties: ["email": "test@example.com"])

        // When
        await mockProvider.identify(user: user)

        // Then
        let identifiedUsers = await mockProvider.identifiedUsers
        #expect(identifiedUsers.count == 1)
        #expect(identifiedUsers.first?.userId == "user123")
        #expect(identifiedUsers.first?.properties["email"] as? String == "test@example.com")
    }

    @Test("Mock provider tracks multiple user identifications")
    func identifyMultipleUsers() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let user1 = TelemetryUser(userId: "user1")
        let user2 = TelemetryUser(userId: "user2")

        // When
        await mockProvider.identify(user: user1)
        await mockProvider.identify(user: user2)

        // Then
        let identifiedUsers = await mockProvider.identifiedUsers
        #expect(identifiedUsers.count == 2)
        #expect(identifiedUsers[0].userId == "user1")
        #expect(identifiedUsers[1].userId == "user2")
    }

    @Test("Mock provider tracks screens correctly")
    func trackScreen() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let screen = TelemetryScreen(name: "HomeView", properties: ["section": "main"])

        // When
        await mockProvider.screen(screen: screen)

        // Then
        let trackedScreens = await mockProvider.trackedScreens
        #expect(trackedScreens.count == 1)
        #expect(trackedScreens.first?.name == "HomeView")
        #expect(trackedScreens.first?.properties["section"] as? String == "main")
    }

    @Test("Mock provider tracks multiple screens")
    func trackMultipleScreens() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let screen1 = TelemetryScreen(name: "HomeView")
        let screen2 = TelemetryScreen(name: "SettingsView")

        // When
        await mockProvider.screen(screen: screen1)
        await mockProvider.screen(screen: screen2)

        // Then
        let trackedScreens = await mockProvider.trackedScreens
        #expect(trackedScreens.count == 2)
        #expect(trackedScreens[0].name == "HomeView")
        #expect(trackedScreens[1].name == "SettingsView")
    }

    @Test("Mock provider returns feature flag value")
    func getFeatureFlag() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.setFeatureFlag(true, forKey: "test_flag")

        // When
        let value = await mockProvider.getFeatureFlag(key: "test_flag", defaultValue: false)

        // Then
        #expect(value == true)
    }

    @Test("Mock provider returns default value when feature flag not set")
    func getFeatureFlagWithDefaultValue() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        let value = await mockProvider.getFeatureFlag(key: "unknown_flag", defaultValue: true)

        // Then
        #expect(value == true)
    }

    @Test("Mock provider returns feature flag payload string")
    func getFeatureFlagPayloadString() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.setFeatureFlagPayload("test_payload", forKey: "test_flag")

        // When
        let payload = await mockProvider.getFeatureFlagPayloadString(key: "test_flag")

        // Then
        #expect(payload == "test_payload")
    }

    @Test("Mock provider returns empty string when feature flag payload not set")
    func getFeatureFlagPayloadStringWithEmptyDefault() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        let payload = await mockProvider.getFeatureFlagPayloadString(key: "unknown_flag")

        // Then
        #expect(payload == "")
    }

    @Test("Mock provider reset clears all data")
    func reset() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.track(event: TelemetryEvent(name: "event1"))
        await mockProvider.identify(user: TelemetryUser(userId: "user1"))
        await mockProvider.screen(screen: TelemetryScreen(name: "HomeView"))

        // When
        await mockProvider.reset()

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        let identifiedUsers = await mockProvider.identifiedUsers
        let trackedScreens = await mockProvider.trackedScreens
        let resetCount = await mockProvider.resetCallCount

        #expect(trackedEvents.isEmpty)
        #expect(identifiedUsers.isEmpty)
        #expect(trackedScreens.isEmpty)
        #expect(resetCount == 1)
    }

    @Test("Mock provider reset increments call count")
    func resetCallCount() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        await mockProvider.reset()
        await mockProvider.reset()
        await mockProvider.reset()

        // Then
        let resetCount = await mockProvider.resetCallCount
        #expect(resetCount == 3)
    }

    @Test("Mock provider flush increments call count")
    func flush() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        await mockProvider.flush()

        // Then
        let flushCount = await mockProvider.flushCallCount
        #expect(flushCount == 1)
    }

    @Test("Mock provider flush increments call count multiple times")
    func flushCallCount() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        await mockProvider.flush()
        await mockProvider.flush()

        // Then
        let flushCount = await mockProvider.flushCallCount
        #expect(flushCount == 2)
    }

    @Test("Mock provider didTrack helper returns true when event tracked")
    func didTrackEventHelper() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.track(event: TelemetryEvent(name: "button_clicked"))

        // When
        let didTrack = await mockProvider.didTrack(eventName: "button_clicked")

        // Then
        #expect(didTrack == true)
    }

    @Test("Mock provider didTrack helper returns false when event not tracked")
    func didTrackEventHelperNotFound() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.track(event: TelemetryEvent(name: "button_clicked"))

        // When
        let didTrack = await mockProvider.didTrack(eventName: "other_event")

        // Then
        #expect(didTrack == false)
    }

    @Test("Mock provider lastEvent returns most recent event")
    func lastEvent() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.track(event: TelemetryEvent(name: "event1"))
        await mockProvider.track(event: TelemetryEvent(name: "event2"))
        await mockProvider.track(event: TelemetryEvent(name: "event3"))

        // When
        let lastEvent = await mockProvider.lastEvent

        // Then
        #expect(lastEvent?.name == "event3")
    }

    @Test("Mock provider lastEvent returns nil when no events tracked")
    func lastEventNil() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        let lastEvent = await mockProvider.lastEvent

        // Then
        #expect(lastEvent == nil)
    }

    @Test("Mock provider lastUser returns most recent user")
    func lastUser() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.identify(user: TelemetryUser(userId: "user1"))
        await mockProvider.identify(user: TelemetryUser(userId: "user2"))

        // When
        let lastUser = await mockProvider.lastUser

        // Then
        #expect(lastUser?.userId == "user2")
    }

    @Test("Mock provider lastUser returns nil when no users identified")
    func lastUserNil() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        let lastUser = await mockProvider.lastUser

        // Then
        #expect(lastUser == nil)
    }

    @Test("Mock provider lastScreen returns most recent screen")
    func lastScreen() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.screen(screen: TelemetryScreen(name: "HomeView"))
        await mockProvider.screen(screen: TelemetryScreen(name: "SettingsView"))

        // When
        let lastScreen = await mockProvider.lastScreen

        // Then
        #expect(lastScreen?.name == "SettingsView")
    }

    @Test("Mock provider lastScreen returns nil when no screens tracked")
    func lastScreenNil() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When
        let lastScreen = await mockProvider.lastScreen

        // Then
        #expect(lastScreen == nil)
    }

    @Test("Mock provider clearAll removes all data and resets counters")
    func clearAll() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.track(event: TelemetryEvent(name: "event1"))
        await mockProvider.identify(user: TelemetryUser(userId: "user1"))
        await mockProvider.screen(screen: TelemetryScreen(name: "HomeView"))
        await mockProvider.setFeatureFlag(true, forKey: "test_flag")
        await mockProvider.setFeatureFlagPayload("payload", forKey: "test_flag")
        await mockProvider.flush()
        await mockProvider.reset()

        // When
        await mockProvider.clearAll()

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        let identifiedUsers = await mockProvider.identifiedUsers
        let trackedScreens = await mockProvider.trackedScreens
        let resetCount = await mockProvider.resetCallCount
        let flushCount = await mockProvider.flushCallCount

        #expect(trackedEvents.isEmpty)
        #expect(identifiedUsers.isEmpty)
        #expect(trackedScreens.isEmpty)
        #expect(resetCount == 0)
        #expect(flushCount == 0)
    }
}
