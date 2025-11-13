import ProjectDescription

let project = Project(
    name: "Telemetry",
    organizationName: "m",
    settings: .settings(
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "Telemetry",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "m.telemetry",
            sources: [
                "Sources/**"
            ],
            dependencies: [
                .external(name: "PostHog")
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "6.0",
                    "IPHONEOS_DEPLOYMENT_TARGET": "26.0"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ],
                defaultSettings: .recommended
            )
        ),
        .target(
            name: "TelemetryTests",
            destinations: [.iPhone, .iPad, .mac],
            product: .unitTests,
            bundleId: "m.telemetry.tests",
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "Telemetry")
            ]
        )
    ]
)
