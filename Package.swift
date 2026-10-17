// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Scribo",
    platforms: [.macOS(.v13)],
    targets: [
        // All app logic + UI types live here so they can be unit-tested.
        .target(
            name: "ScriboCore",
            path: "Sources/ScriboCore",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        // Thin executable: just the entry point.
        .executableTarget(
            name: "Scribo",
            dependencies: ["ScriboCore"],
            path: "Sources/Scribo",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ScriboCoreTests",
            dependencies: ["ScriboCore"],
            path: "Tests/ScriboCoreTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
