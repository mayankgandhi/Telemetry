import Testing
@testable import Telemetry

@Suite("TelemetryService Tests")
struct TelemetryServiceTests {

    @Test("Track event records event in mock provider")
    func trackEvent() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - fire-and-forget, need to wait for background task
        service.track(event: "button_tapped", properties: ["screen": "home"])

        // Give the background task time to complete
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1)
        #expect(trackedEvents.first?.name == "button_tapped")

        let properties = trackedEvents.first?.properties ?? [:]
        #expect(properties["screen"] as? String == "home")
    }

    @Test("Track event with model records event in mock provider")
    func trackEventWithModel() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let event = TelemetryEvent(
            name: "screen_viewed",
            properties: ["screen": "settings", "timestamp": 12345]
        )

        // When
        service.track(event: event)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1)
        #expect(trackedEvents.first?.name == "screen_viewed")
    }

    @Test("Identify user records user in mock provider")
    func identifyUser() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.identify(userId: "user123", properties: ["email": "test@example.com", "plan": "pro"])
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let identifiedUsers = await mockProvider.identifiedUsers
        #expect(identifiedUsers.count == 1)
        #expect(identifiedUsers.first?.userId == "user123")

        let properties = identifiedUsers.first?.properties ?? [:]
        #expect(properties["email"] as? String == "test@example.com")
        #expect(properties["plan"] as? String == "pro")
    }

    @Test("Identify user with model records user in mock provider")
    func identifyUserWithModel() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let user = TelemetryUser(
            userId: "user456",
            properties: ["name": "John Doe"]
        )

        // When
        service.identify(user: user)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let identifiedUsers = await mockProvider.identifiedUsers
        #expect(identifiedUsers.count == 1)
        #expect(identifiedUsers.first?.userId == "user456")
    }

    @Test("Screen tracking records screen in mock provider")
    func trackScreen() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.screen(screen: "HomeView", properties: ["section": "main"])
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let trackedScreens = await mockProvider.trackedScreens
        #expect(trackedScreens.count == 1)
        #expect(trackedScreens.first?.name == "HomeView")

        let properties = trackedScreens.first?.properties ?? [:]
        #expect(properties["section"] as? String == "main")
    }

    @Test("Screen tracking with model records screen in mock provider")
    func trackScreenWithModel() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let screen = TelemetryScreen(
            name: "SettingsView",
            properties: ["theme": "dark"]
        )

        // When
        service.screen(screen: screen)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let trackedScreens = await mockProvider.trackedScreens
        #expect(trackedScreens.count == 1)
        #expect(trackedScreens.first?.name == "SettingsView")
    }

    @Test("Get feature flag returns configured value")
    func getFeatureFlag() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        await mockProvider.setFeatureFlag(true, forKey: "new_ui")

        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        let isEnabled = await service.getFeatureFlag(key: "new_ui")

        // Then
        #expect(isEnabled == true)
    }

    @Test("Get feature flag returns default value when not found")
    func getFeatureFlagWithDefault() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        let isEnabled = await service.getFeatureFlag(key: "unknown_flag", defaultValue: false)

        // Then
        #expect(isEnabled == false)
    }

    @Test("Reset clears provider data")
    func resetProvider() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        service.track(event: "test_event")
        try? await Task.sleep(for: .milliseconds(100))

        // When - use async version to wait for completion
        await service.resetAsync()

        // Then
        let resetCount = await mockProvider.resetCallCount
        #expect(resetCount == 1)

        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.isEmpty)
    }

    @Test("Flush triggers provider flush")
    func flushProvider() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - use async version to wait for completion
        await service.flushAsync()

        // Then
        let flushCount = await mockProvider.flushCallCount
        #expect(flushCount == 1)
    }

    @Test("Multiple events tracked sequentially")
    func multipleEvents() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.track(event: "event1")
        service.track(event: "event2")
        service.track(event: "event3")
        try? await Task.sleep(for: .milliseconds(200))

        // Then
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 3)
        #expect(trackedEvents[0].name == "event1")
        #expect(trackedEvents[1].name == "event2")
        #expect(trackedEvents[2].name == "event3")
    }
}
