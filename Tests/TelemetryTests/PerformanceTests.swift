import Testing
import Foundation
@testable import Telemetry

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Track events are fire-and-forget (non-blocking)")
    func trackingIsNonBlocking() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - measure time to call track 100 times
        let start = Date()
        for i in 0..<100 {
            service.track(event: "event_\(i)", properties: ["index": i])
        }
        let duration = Date().timeIntervalSince(start)

        // Then - should complete nearly instantly (< 10ms)
        // Fire-and-forget should not block the caller
        #expect(duration < 0.01) // Less than 10ms for 100 calls

        // Wait for background tasks to complete
        try? await Task.sleep(for: .seconds(1))

        // Verify all events were tracked
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 100)
    }

    @Test("Concurrent tracking from multiple threads is thread-safe")
    func concurrentTrackingIsThreadSafe() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - track events from multiple concurrent tasks
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<10 {
                        service.track(event: "concurrent_event_\(i)_\(j)")
                    }
                }
            }
        }

        // Wait for all background tasks to complete
        try? await Task.sleep(for: .seconds(1))

        // Then - all 100 events should be tracked without race conditions
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 100)
    }

    @Test("Property conversion is optimized for common types")
    func propertyConversionPerformance() async throws {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "string": "test",
            "int": 42,
            "double": 3.14,
            "bool": true,
            "date": Date(),
            "array": [1, 2, 3],
            "dict": ["key": "value"]
        ]

        // When - measure a batch large enough that scheduler noise does not dominate.
        //
        // At 1000 iterations this measured ~0.005s, small enough that CPU contention from the
        // other 101 tests running in parallel moved it by 2-3x and no threshold was both
        // stable and meaningful. 10,000 iterations costs ~0.2s and separates signal from
        // noise by roughly 50x (see below).
        let start = Date()
        for _ in 0..<10_000 {
            _ = provider.convertProperties(properties)
        }
        let duration = Date().timeIntervalSince(start)

        // Then - guard against an order-of-magnitude regression, not a precise budget.
        //
        // Measured in an unoptimized `swift test --parallel` build: 0.12-0.23s as written,
        // versus 7.8-8.7s if the cached `ISO8601DateFormatter` is replaced by one allocation
        // per date value - the regression this test exists to catch. 2s sits well clear of
        // both, leaving room for a slower shared CI runner without going quiet on the bug.
        //
        // The previous 0.1s bound was calibrated against a since-removed copy of
        // `convertProperties` in this file that did allocate a formatter per call, so it sat
        // right on that copy's measurement and failed about half the time.
        #expect(duration < 2.0)
    }

    @Test("Provider configuration is thread-safe")
    func providerConfigurationIsThreadSafe() async throws {
        // Given
        let service = TelemetryService()
        let mockProvider = MockTelemetryProvider()

        // When - configure from multiple threads simultaneously
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await service.configureAsync(provider: mockProvider)
                }
            }
        }

        // Then - configuration should succeed without crashes or race conditions
        service.track(event: "test_event")
        try? await Task.sleep(for: .milliseconds(100))

        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1)
    }

    @Test("Large property dictionaries are handled efficiently")
    func largePropertyDictionaryPerformance() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // Create a large properties dictionary
        var largeProperties: [String: any Sendable] = [:]
        for i in 0..<100 {
            largeProperties["key_\(i)"] = "value_\(i)"
        }

        // When - measure time to track event with large properties
        let start = Date()
        service.track(event: "large_event", properties: largeProperties)
        let duration = Date().timeIntervalSince(start)

        // Then - should still be fast (< 5ms)
        #expect(duration < 0.005) // Less than 5ms

        // Wait for background processing
        try? await Task.sleep(for: .milliseconds(200))

        // Verify event was tracked
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1)
        #expect(trackedEvents.first?.properties.count == 100)
    }

    @Test("Identify operations are fire-and-forget")
    func identifyIsNonBlocking() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - measure time to call identify
        let start = Date()
        service.identify(userId: "user123", properties: ["email": "test@example.com"])
        let duration = Date().timeIntervalSince(start)

        // Then - should complete instantly
        #expect(duration < 0.001) // Less than 1ms

        // Wait for background task
        try? await Task.sleep(for: .milliseconds(100))

        // Verify identification occurred
        let identifiedUsers = await mockProvider.identifiedUsers
        #expect(identifiedUsers.count == 1)
    }

    @Test("Screen tracking is fire-and-forget")
    func screenTrackingIsNonBlocking() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - measure time to call screen
        let start = Date()
        service.screen(screen: "HomeView", properties: ["tab": "main"])
        let duration = Date().timeIntervalSince(start)

        // Then - should complete instantly
        #expect(duration < 0.001) // Less than 1ms

        // Wait for background task
        try? await Task.sleep(for: .milliseconds(100))

        // Verify screen was tracked
        let trackedScreens = await mockProvider.trackedScreens
        #expect(trackedScreens.count == 1)
    }

    @Test("Mock provider handles high volume without memory issues")
    func mockProviderHighVolumeHandling() async throws {
        // Given
        let mockProvider = MockTelemetryProvider()
        let service = TelemetryService()
        await service.configureAsync(provider: mockProvider)

        // When - track many events
        for i in 0..<1000 {
            service.track(event: "high_volume_event_\(i)")
        }

        // Wait for background tasks
        try? await Task.sleep(for: .seconds(2))

        // Then - all events should be recorded
        let trackedEvents = await mockProvider.trackedEvents
        #expect(trackedEvents.count == 1000)

        // Clean up for memory test
        await mockProvider.clearAll()
        let clearedEvents = await mockProvider.trackedEvents
        #expect(clearedEvents.isEmpty)
    }
}
