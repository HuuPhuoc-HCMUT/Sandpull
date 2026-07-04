// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PullTimer",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PullTimer",
            path: "Sources/PullTimer",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ]
        )
    ]
)
