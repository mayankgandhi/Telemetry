# Telemetry

A flexible, protocol-based analytics framework for iOS apps. Telemetry provides a clean abstraction layer over analytics services, making it easy to track events, identify users, and manage feature flags while maintaining the ability to migrate between analytics providers with minimal code changes.

## Features

- **Protocol-based abstraction** - Easily swap analytics providers without changing app code
- **Type-safe models** - Swift-native models for events, users, and screens
- **PostHog integration** - Ready-to-use PostHog implementation
- **Feature flags** - Remote feature flag support
- **Mock provider** - Built-in mock for testing and SwiftUI previews
- **Thread-safe** - Lock-based synchronization for Swift 6.0 concurrency
- **Zero setup tracking** - Gracefully handles unconfigured state for testing
- **High performance** - Fire-and-forget tracking, no main thread blocking

## Performance

Telemetry is designed for **maximum performance** with zero impact on UI responsiveness:

### Fire-and-Forget Tracking
All tracking methods (`track`, `identify`, `screen`, etc.) are **fire-and-forget**:
- Return immediately without blocking the caller
- Execute on background threads (`.utility` priority)
- **Never block the main thread** or UI

```swift
// This returns instantly (< 1ms), work happens in background
TelemetryService.shared.track(event: "button_tapped")
```

### Thread Safety
- **OSAllocatedUnfairLock** for provider access (minimal overhead)
- **No actor serialization bottlenecks** - can track from multiple threads concurrently
- **No data races** - all state access is properly synchronized

### Optimizations
- **Cached date formatter** - Reused across all property conversions
- **Pattern matching** - Optimized type checking for property conversion
- **Capacity pre-allocation** - Dictionary capacity reserved for better memory performance
- **Background processing** - All PostHog SDK calls run off the main thread
- **No MainActor blocking** - PostHog SDK handles its own threading

### Benchmarks

From our performance tests (`PerformanceTests.swift`):

- **Fire-and-forget overhead**: < 0.1ms per tracking call (100 calls in < 10ms)
- **Concurrent tracking**: 100 events from 10 threads simultaneously without race conditions
- **Property conversion**: 1000 conversions in < 100ms
- **Large properties**: 100-key dictionary tracking in < 5ms
- **High volume**: 1000 events tracked without memory issues

### When to Use Async Methods

For operations that need confirmation of completion:
- `flushAsync()` - Before app termination to ensure all events are sent
- `resetAsync()` - During logout when you need to wait for session clear
- `getFeatureFlag()` - Always async since it needs to return a value

All other operations use the fire-and-forget synchronous methods for best performance.

## Installation

The Telemetry framework is already included in the Monorepo workspace. To use it in your app:

1. Add Telemetry as a dependency in your `Project.swift`:

```swift
dependencies: [
    .project(target: "Telemetry", path: "../../Telemetry")
]
```

2. Import the framework:

```swift
import Telemetry
```

## Quick Start

### 1. Configure on App Launch

Configure Telemetry during your app initialization (typically in your `@main` app struct or `ApplicationService`):

```swift
import Telemetry

@main
struct MyApp: App {
    init() {
        // Configure with PostHog (synchronous, completes immediately)
        let provider = PostHogProvider(
            apiKey: "your_posthog_api_key",
            host: "https://us.i.posthog.com"
        )

        // Configure provider asynchronously in background
        Task {
            await provider.configure()
        }

        // Configure telemetry service (synchronous)
        TelemetryService.shared.configure(provider: provider)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Track Events

```swift
// Simple event tracking (fire-and-forget, no await needed!)
TelemetryService.shared.track(event: "button_tapped")

// Event with properties (returns immediately, processes in background)
TelemetryService.shared.track(
    event: "purchase_completed",
    properties: [
        "product": "premium_subscription",
        "price": 9.99,
        "currency": "USD"
    ]
)

// Using TelemetryEvent model
let event = TelemetryEvent(
    name: "video_played",
    properties: ["duration": 120, "quality": "HD"]
)
TelemetryService.shared.track(event: event)

// Alternative: Use async version if you need to wait for completion
await TelemetryService.shared.trackAsync(
    event: "critical_event",
    properties: ["important": true]
)
```

### 3. Identify Users

```swift
// Identify user (fire-and-forget, no await needed!)
TelemetryService.shared.identify(
    userId: "user_12345",
    properties: [
        "email": "user@example.com",
        "plan": "premium",
        "signup_date": Date()
    ]
)

// Using TelemetryUser model
let user = TelemetryUser(
    userId: "user_12345",
    properties: ["name": "John Doe"]
)
TelemetryService.shared.identify(user: user)
```

### 4. Track Screen Views

```swift
// Track screen view (fire-and-forget, no await needed!)
TelemetryService.shared.screen(
    screen: "HomeView",
    properties: ["section": "dashboard"]
)

// Using TelemetryScreen model
let screen = TelemetryScreen(
    name: "SettingsView",
    properties: ["theme": "dark"]
)
TelemetryService.shared.screen(screen: screen)
```

### 5. Feature Flags

```swift
// Check feature flag
let isNewUIEnabled = await TelemetryService.shared.getFeatureFlag(
    key: "new_ui_enabled",
    defaultValue: false
)

if isNewUIEnabled {
    // Show new UI
} else {
    // Show old UI
}
```

### 6. Session Management

```swift
// Reset session (fire-and-forget, for non-critical logout)
TelemetryService.shared.reset()

// Reset session and wait for completion (recommended for logout)
await TelemetryService.shared.resetAsync()

// Flush pending events (fire-and-forget)
TelemetryService.shared.flush()

// Flush and wait for completion (recommended before app termination)
await TelemetryService.shared.flushAsync()
```

## Testing

### Using MockTelemetryProvider

For unit tests and SwiftUI previews, use the built-in `MockTelemetryProvider`:

```swift
import Telemetry

// In your test
@Test func testEventTracking() async {
    let mockProvider = MockTelemetryProvider()
    let service = TelemetryService()
    await service.configure(provider: mockProvider)

    // Track an event
    await service.track(event: "test_event")

    // Verify
    let events = await mockProvider.trackedEvents
    #expect(events.count == 1)
    #expect(events.first?.name == "test_event")
}

// In SwiftUI preview
#Preview {
    ContentView()
        .task {
            let mockProvider = MockTelemetryProvider()
            await TelemetryService.shared.configure(provider: mockProvider)
        }
}
```

### MockTelemetryProvider Features

```swift
let mockProvider = MockTelemetryProvider()

// Access tracked data
await mockProvider.trackedEvents      // All tracked events
await mockProvider.identifiedUsers    // All identified users
await mockProvider.trackedScreens     // All tracked screens

// Configure feature flags
await mockProvider.featureFlags["new_feature"] = true

// Helpers
await mockProvider.didTrack(eventName: "button_clicked")  // Check if event was tracked
await mockProvider.lastEvent                              // Get last tracked event
await mockProvider.clearAll()                             // Clear all data
```

## Migrating to Another Analytics Provider

One of Telemetry's key benefits is the ability to migrate to a different analytics provider with minimal code changes.

### Example: Switching from PostHog to Mixpanel

1. Create a new provider implementation:

```swift
import Telemetry

public actor MixpanelProvider: TelemetryProvider {
    private let apiKey: String

    public init(apiKey: String) {
        self.apiKey = apiKey
        // Initialize Mixpanel SDK
    }

    public func track(event: TelemetryEvent) async {
        // Implement using Mixpanel SDK
    }

    public func identify(user: TelemetryUser) async {
        // Implement using Mixpanel SDK
    }

    // ... implement other protocol methods
}
```

2. Update your app initialization:

```swift
// Before
let provider = PostHogProvider(apiKey: "...")
TelemetryService.shared.configure(provider: provider)

// After
let provider = MixpanelProvider(apiKey: "...")
TelemetryService.shared.configure(provider: provider)
```

3. That's it! All your existing tracking code remains unchanged.

## Architecture

```
Telemetry/
├── Sources/
│   ├── TelemetryProvider.swift          # Protocol definition
│   ├── TelemetryService.swift           # Main service singleton
│   ├── PostHogProvider.swift            # PostHog implementation
│   ├── Models/
│   │   ├── TelemetryEvent.swift         # Event model
│   │   ├── TelemetryUser.swift          # User model
│   │   └── TelemetryScreen.swift        # Screen model
│   └── Mock/
│       └── MockTelemetryProvider.swift  # Mock for testing
└── Tests/
    └── TelemetryTests/
        └── TelemetryServiceTests.swift  # Unit tests
```

## Best Practices

1. **Configure once** - Initialize Telemetry during app launch, not before each tracking call
2. **Use fire-and-forget methods** - Use synchronous tracking methods for best performance (no `await`)
3. **Use async variants when needed** - Use `trackAsync()`, `resetAsync()`, `flushAsync()` only when you need to wait for completion
4. **Use type-safe properties** - Leverage Swift's type system for event properties
5. **Meaningful event names** - Use descriptive, consistent event naming (e.g., `button_tapped`, `screen_viewed`)
6. **Test with mock** - Use `MockTelemetryProvider` in tests to verify tracking behavior
7. **Flush before termination** - Call `flushAsync()` (with await) before app termination to ensure all events are sent
8. **Reset on logout** - Always call `resetAsync()` (with await) when users log out to ensure session is cleared

## Example Integration

Here's a complete example of integrating Telemetry into an app:

```swift
import SwiftUI
import Telemetry

@main
struct WalnutApp: App {
    init() {
        configureTelemetry()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func configureTelemetry() {
        #if DEBUG
        // Use mock in debug for privacy
        let provider = MockTelemetryProvider()
        TelemetryService.shared.configure(provider: provider)
        #else
        // Use PostHog in production
        let provider = PostHogProvider(
            apiKey: "phc_your_api_key",
            host: "https://us.i.posthog.com"
        )

        // Configure provider in background
        Task {
            await provider.configure()
        }

        // Configure service immediately (synchronous)
        TelemetryService.shared.configure(provider: provider)
        #endif
    }
}

struct ContentView: View {
    var body: some View {
        Button("Subscribe") {
            // Fire-and-forget tracking (no Task needed!)
            TelemetryService.shared.track(
                event: "subscribe_button_tapped",
                properties: ["screen": "home"]
            )
        }
        .onAppear {
            // Track screen view (no await needed!)
            TelemetryService.shared.screen(screen: "HomeView")
        }
    }
}
```

## License

Copyright © 2025 m. All rights reserved.
