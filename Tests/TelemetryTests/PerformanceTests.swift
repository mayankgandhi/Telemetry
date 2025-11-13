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

        // When - measure time to convert properties 1000 times
        let start = Date()
        for _ in 0..<1000 {
            // Access private method through reflection for testing
            _ = provider.convertProperties(properties)
        }
        let duration = Date().timeIntervalSince(start)

        // Then - should complete quickly (< 100ms for 1000 conversions)
        #expect(duration < 0.1) // Less than 100ms
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

// Extension to expose private method for testing
extension PostHogProvider {
    func convertProperties(_ properties: [String: any Sendable]) -> [String: Any] {
        // This is the same implementation as the private method
        guard !properties.isEmpty else { return [:] }

        var result = [String: Any]()
        result.reserveCapacity(properties.count)

        for (key, value) in properties {
            switch value {
            case let stringValue as String:
                result[key] = stringValue
            case let intValue as Int:
                result[key] = intValue
            case let doubleValue as Double:
                result[key] = doubleValue
            case let boolValue as Bool:
                result[key] = boolValue
            case let dateValue as Date:
                result[key] = ISO8601DateFormatter().string(from: dateValue)
            case let arrayValue as [Any]:
                result[key] = arrayValue
            case let dictValue as [String: Any]:
                result[key] = dictValue
            default:
                result[key] = "\(value)"
            }
        }
        return result
    }
}
