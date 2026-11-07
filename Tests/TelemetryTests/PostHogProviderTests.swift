import Testing
import Foundation
@testable import Telemetry

@Suite("PostHogProvider Tests")
struct PostHogProviderTests {

    @Test("PostHogProvider initializes with API key and default host")
    func initializeWithDefaultHost() {
        // Given & When
        let provider = PostHogProvider(apiKey: "test_api_key")

        // Then - assert what `init` actually stored. (The previous `provider != nil` is always
        // true for a non-optional value, so it asserted nothing and the compiler warned on it.)
        #expect(provider.apiKey == "test_api_key")
        #expect(provider.host == "https://us.i.posthog.com")
    }

    @Test("PostHogProvider initializes with API key and custom host")
    func initializeWithCustomHost() {
        // Given & When
        let provider = PostHogProvider(
            apiKey: "test_api_key",
            host: "https://custom.posthog.com"
        )

        // Then - the custom host must override the default.
        #expect(provider.apiKey == "test_api_key")
        #expect(provider.host == "https://custom.posthog.com")
    }

    @Test("PostHogProvider converts string properties correctly")
    func convertStringProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["name": "John Doe"]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["name"] as? String == "John Doe")
    }

    @Test("PostHogProvider converts integer properties correctly")
    func convertIntegerProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["age": 30, "count": 42]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["age"] as? Int == 30)
        #expect(converted["count"] as? Int == 42)
    }

    @Test("PostHogProvider converts double properties correctly")
    func convertDoubleProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["price": 9.99, "rating": 4.5]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["price"] as? Double == 9.99)
        #expect(converted["rating"] as? Double == 4.5)
    }

    @Test("PostHogProvider converts boolean properties correctly")
    func convertBooleanProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["isActive": true, "isPremium": false]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["isActive"] as? Bool == true)
        #expect(converted["isPremium"] as? Bool == false)
    }

    @Test("PostHogProvider converts date properties to ISO8601 string")
    func convertDateProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let date = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let properties: [String: any Sendable] = ["signupDate": date]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        let dateString = converted["signupDate"] as? String
        #expect(dateString != nil)
        #expect(dateString?.contains("2021") == true)
    }

    @Test("PostHogProvider converts array properties correctly")
    func convertArrayProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["tags": [1, 2, 3]]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        let array = converted["tags"] as? [Int]
        #expect(array?.count == 3)
        #expect(array?[0] == 1)
        #expect(array?[1] == 2)
        #expect(array?[2] == 3)
    }

    @Test("PostHogProvider converts dictionary properties correctly")
    func convertDictionaryProperty() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let metadata: [String: any Sendable] = ["key": "value", "count": 42]
        let properties: [String: any Sendable] = ["metadata": metadata]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        let dict = converted["metadata"] as? [String: Any]
        #expect(dict != nil)
    }

    @Test("PostHogProvider converts mixed property types correctly")
    func convertMixedProperties() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let date = Date()
        let properties: [String: any Sendable] = [
            "string": "text",
            "int": 123,
            "double": 3.14,
            "bool": true,
            "date": date,
            "array": [1, 2, 3]
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted.count == 6)
        #expect(converted["string"] as? String == "text")
        #expect(converted["int"] as? Int == 123)
        #expect(converted["double"] as? Double == 3.14)
        #expect(converted["bool"] as? Bool == true)
        #expect(converted["date"] as? String != nil)
        #expect((converted["array"] as? [Int])?.count == 3)
    }

    @Test("PostHogProvider handles empty properties dictionary")
    func convertEmptyProperties() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [:]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted.isEmpty)
    }

    @Test("PostHogProvider handles large properties dictionary efficiently")
    func convertLargeProperties() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        var properties: [String: any Sendable] = [:]
        for i in 0..<100 {
            properties["key_\(i)"] = "value_\(i)"
        }

        // When
        let start = Date()
        let converted = provider.convertProperties(properties)
        let duration = Date().timeIntervalSince(start)

        // Then
        #expect(converted.count == 100)
        #expect(duration < 0.01) // Should be fast (< 10ms)
    }

    @Test("PostHogProvider property conversion preserves capacity optimization")
    func propertyConversionReservesCapacity() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3"
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then - Verify all properties are converted
        #expect(converted.count == 3)
        #expect(converted["key1"] as? String == "value1")
        #expect(converted["key2"] as? String == "value2")
        #expect(converted["key3"] as? String == "value3")
    }

    @Test("PostHogProvider handles negative numbers correctly")
    func convertNegativeNumbers() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "negativeInt": -42,
            "negativeDouble": -3.14
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["negativeInt"] as? Int == -42)
        #expect(converted["negativeDouble"] as? Double == -3.14)
    }

    @Test("PostHogProvider handles zero values correctly")
    func convertZeroValues() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "zeroInt": 0,
            "zeroDouble": 0.0
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["zeroInt"] as? Int == 0)
        #expect(converted["zeroDouble"] as? Double == 0.0)
    }

    @Test("PostHogProvider handles very large numbers correctly")
    func convertLargeNumbers() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "largeInt": Int.max,
            "largeDouble": Double.greatestFiniteMagnitude
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["largeInt"] as? Int == Int.max)
        #expect(converted["largeDouble"] as? Double == Double.greatestFiniteMagnitude)
    }

    @Test("PostHogProvider handles empty strings correctly")
    func convertEmptyString() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["emptyString": ""]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["emptyString"] as? String == "")
    }

    @Test("PostHogProvider handles special characters in strings")
    func convertSpecialCharacters() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "emoji": "🚀 Hello 👋",
            "unicode": "こんにちは",
            "special": "!@#$%^&*()",
            "newlines": "line1\nline2\nline3"
        ]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        #expect(converted["emoji"] as? String == "🚀 Hello 👋")
        #expect(converted["unicode"] as? String == "こんにちは")
        #expect(converted["special"] as? String == "!@#$%^&*()")
        #expect(converted["newlines"] as? String == "line1\nline2\nline3")
    }

    @Test("PostHogProvider handles empty arrays correctly")
    func convertEmptyArray() {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = ["emptyArray": [] as [any Sendable]]

        // When
        let converted = provider.convertProperties(properties)

        // Then
        let array = converted["emptyArray"] as? [Any]
        #expect(array?.isEmpty == true)
    }

    @Test("PostHogProvider property conversion is thread-safe")
    func propertyConversionIsThreadSafe() async {
        // Given
        let provider = PostHogProvider(apiKey: "test_key")
        let properties: [String: any Sendable] = [
            "key1": "value1",
            "key2": 42,
            "key3": true
        ]

        // When - Convert from multiple threads simultaneously
        //
        // `convertProperties` returns `[String: Any]`, which is not `Sendable` and so cannot
        // be a task group's result type under Swift 6 strict concurrency. Each child task
        // therefore reads the values it cares about and returns a `Sendable` projection,
        // keeping the non-Sendable dictionary inside the task that created it.
        let results = await withTaskGroup(of: ConvertedProperties.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    ConvertedProperties(provider.convertProperties(properties))
                }
            }

            var results: [ConvertedProperties] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Then - All conversions should succeed with same values
        #expect(results.count == 10)
        #expect(results.allSatisfy { $0 == ConvertedProperties(key1: "value1", key2: 42, key3: true) })
    }

    /// `Sendable` projection of a converted property dictionary, used to carry conversion
    /// results out of a child task without moving the non-`Sendable` `[String: Any]`.
    private struct ConvertedProperties: Sendable, Equatable {
        let key1: String?
        let key2: Int?
        let key3: Bool?

        init(key1: String?, key2: Int?, key3: Bool?) {
            self.key1 = key1
            self.key2 = key2
            self.key3 = key3
        }

        init(_ converted: [String: Any]) {
            self.key1 = converted["key1"] as? String
            self.key2 = converted["key2"] as? Int
            self.key3 = converted["key3"] as? Bool
        }
    }
}
