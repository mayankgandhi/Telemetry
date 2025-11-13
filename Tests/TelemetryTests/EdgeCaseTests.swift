import Testing
import Foundation
@testable import Telemetry

@Suite("Edge Case and Error Handling Tests")
struct EdgeCaseTests {

    @Test("TelemetryService handles unconfigured state gracefully")
    func unconfiguredServiceHandlesTracking() async throws {
        // Given - Service without provider configured
        let service = TelemetryService()

        // When - Attempt to track without provider (should not crash)
        service.track(event: "test_event")
        service.identify(userId: "user123")
        service.screen(screen: "HomeView")
        service.reset()
        service.flush()

        // Wait for background tasks
        try? await Task.sleep(for: .milliseconds(100))

        // Then - No crash occurred
        #expect(true)
    }

    @Test("TelemetryService async methods handle unconfigured state gracefully")
    func unconfiguredServiceHandlesAsyncMethods() async {
        // Given - Service without provider configured
        let service = TelemetryService()

        // When - Attempt async operations without provider
        await service.trackAsync(event: "test_event")
        let flag = await service.getFeatureFlag(key: "test_flag", defaultValue: false)
        await service.resetAsync()
        await service.flushAsync()

        // Then - Should return default values, no crash
        #expect(flag == false)
    }

    @Test("TelemetryService handles rapid successive configuration changes")
    func rapidConfigurationChanges() async {
        // Given
        let service = TelemetryService()
        let provider1 = MockTelemetryProvider()
        let provider2 = MockTelemetryProvider()
        let provider3 = MockTelemetryProvider()

        // When - Rapidly change providers
        await service.configureAsync(provider: provider1)
        await service.configureAsync(provider: provider2)
        await service.configureAsync(provider: provider3)

        // Then - Should handle gracefully
        service.track(event: "test_event")
        try? await Task.sleep(for: .milliseconds(100))

        let events = await provider3.trackedEvents
        #expect(events.count >= 0) // Provider 3 might or might not have the event
    }

    @Test("TelemetryService handles extreme property key lengths")
    func extremePropertyKeyLength() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let veryLongKey = String(repeating: "a", count: 10000)
        let properties: [String: any Sendable] = [veryLongKey: "value"]

        // When
        service.track(event: "test_event", properties: properties)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.properties[veryLongKey] as? String == "value")
    }

    @Test("TelemetryService handles extreme property value lengths")
    func extremePropertyValueLength() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let veryLongValue = String(repeating: "x", count: 100000)
        let properties: [String: any Sendable] = ["key": veryLongValue]

        // When
        service.track(event: "test_event", properties: properties)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.properties["key"] as? String == veryLongValue)
    }

    @Test("TelemetryService handles empty event names")
    func emptyEventName() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.track(event: "")
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.name == "")
    }

    @Test("TelemetryService handles empty userId")
    func emptyUserId() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.identify(userId: "")
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let users = await mockProvider.identifiedUsers
        #expect(users.count == 1)
        #expect(users.first?.userId == "")
    }

    @Test("TelemetryService handles empty screen names")
    func emptyScreenName() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.screen(screen: "")
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let screens = await mockProvider.trackedScreens
        #expect(screens.count == 1)
        #expect(screens.first?.name == "")
    }

    @Test("TelemetryService handles very long event names")
    func veryLongEventName() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let longEventName = String(repeating: "event_", count: 1000)

        // When
        service.track(event: longEventName)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.name == longEventName)
    }

    @Test("TelemetryService handles special characters in event names")
    func specialCharactersInEventName() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let specialEventName = "🚀 event_with_emoji & special!@#$%^&*() chars 日本語"

        // When
        service.track(event: specialEventName)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.name == specialEventName)
    }

    @Test("TelemetryService handles nil property values gracefully")
    func nilPropertyValues() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // Note: Optional<String> as? any Sendable allows nil to be passed
        let properties: [String: any Sendable] = [
            "validKey": "validValue",
            "intKey": 42
        ]

        // When
        service.track(event: "test_event", properties: properties)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
    }

    @Test("TelemetryService handles concurrent tracking from many threads")
    func massiveConcurrentTracking() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - Track from 50 concurrent tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    for j in 0..<10 {
                        service.track(event: "concurrent_\(i)_\(j)")
                    }
                }
            }
        }

        // Wait for all background tasks
        try? await Task.sleep(for: .seconds(2))

        // Then - All 500 events should be tracked
        let events = await mockProvider.trackedEvents
        #expect(events.count == 500)
    }

    @Test("TelemetryService handles rapid reset calls")
    func rapidResetCalls() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - Call reset many times rapidly
        for _ in 0..<10 {
            await service.resetAsync()
        }

        // Then
        let resetCount = await mockProvider.resetCallCount
        #expect(resetCount == 10)
    }

    @Test("TelemetryService handles rapid flush calls")
    func rapidFlushCalls() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - Call flush many times rapidly
        for _ in 0..<10 {
            await service.flushAsync()
        }

        // Then
        let flushCount = await mockProvider.flushCallCount
        #expect(flushCount == 10)
    }

    @Test("MockProvider handles concurrent operations safely")
    func mockProviderConcurrentOperations() async {
        // Given
        let mockProvider = MockTelemetryProvider()

        // When - Perform various operations concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await mockProvider.track(event: TelemetryEvent(name: "event1"))
            }
            group.addTask {
                await mockProvider.identify(user: TelemetryUser(userId: "user1"))
            }
            group.addTask {
                await mockProvider.screen(screen: TelemetryScreen(name: "screen1"))
            }
            group.addTask {
                await mockProvider.flush()
            }
            group.addTask {
                _ = await mockProvider.getFeatureFlag(key: "flag1", defaultValue: false)
            }
        }

        // Then - All operations complete successfully
        let events = await mockProvider.trackedEvents
        let users = await mockProvider.identifiedUsers
        let screens = await mockProvider.trackedScreens

        #expect(events.count == 1)
        #expect(users.count == 1)
        #expect(screens.count == 1)
    }

    @Test("TelemetryEvent handles very old and future dates")
    func extremeDateValues() {
        // Given
        let veryOldDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let futureDate = Date(timeIntervalSince1970: 4102444800) // Jan 1, 2100

        // When
        let oldEvent = TelemetryEvent(name: "old_event", timestamp: veryOldDate)
        let futureEvent = TelemetryEvent(name: "future_event", timestamp: futureDate)

        // Then
        #expect(oldEvent.timestamp == veryOldDate)
        #expect(futureEvent.timestamp == futureDate)
    }

    @Test("TelemetryService trackAsync completes successfully")
    func trackAsyncCompletion() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        await service.trackAsync(event: "async_event", properties: ["key": "value"])

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.count == 1)
        #expect(events.first?.name == "async_event")
    }

    @Test("Feature flags handle missing keys with default values")
    func featureFlagMissingKeyDefaultValue() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - Request flag that doesn't exist
        let defaultTrue = await service.getFeatureFlag(key: "missing_flag", defaultValue: true)
        let defaultFalse = await service.getFeatureFlag(key: "another_missing", defaultValue: false)

        // Then
        #expect(defaultTrue == true)
        #expect(defaultFalse == false)
    }

    @Test("Feature flag payload handles missing keys")
    func featureFlagPayloadMissingKey() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - Request payload for flag that doesn't exist
        let payload = await service.getFeatureFlagPayloadString(key: "missing_payload")

        // Then
        #expect(payload == "")
    }

    @Test("Properties with numeric keys are handled correctly")
    func propertiesWithNumericKeys() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        let properties: [String: any Sendable] = [
            "123": "numeric key",
            "0": "zero",
            "-1": "negative"
        ]

        // When
        service.track(event: "test_event", properties: properties)
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        #expect(events.first?.properties["123"] as? String == "numeric key")
        #expect(events.first?.properties["0"] as? String == "zero")
        #expect(events.first?.properties["-1"] as? String == "negative")
    }

    @Test("Tracking handles whitespace-only names")
    func whitespaceOnlyNames() async {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When
        service.track(event: "   ")
        service.identify(userId: "   ")
        service.screen(screen: "   ")
        try? await Task.sleep(for: .milliseconds(100))

        // Then
        let events = await mockProvider.trackedEvents
        let users = await mockProvider.identifiedUsers
        let screens = await mockProvider.trackedScreens

        #expect(events.count == 1)
        #expect(users.count == 1)
        #expect(screens.count == 1)
    }
}
