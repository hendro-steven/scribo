// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Scribo",
    platforms: [.macOS(.v13)],
    targets: [
        // All app logic + UI types live here so they can be unit-tested.
        .target(
            name: "ScriboCore",
            path: "Sources/ScriboCore"
        ),
        // Thin executable: just the entry point.
        .executableTarget(
            name: "Scribo",
            dependencies: ["ScriboCore"],
            path: "Sources/Scribo"
        ),
        .testTarget(
            name: "ScriboCoreTests",
            dependencies: ["ScriboCore"],
            path: "Tests/ScriboCoreTests"
        )
    ],
    // Package-level language mode (applied to all targets). Declared here rather
    // than per-target swiftSettings so universal (multi-arch) builds work —
    // per-target .swiftLanguageMode breaks `swift build --arch arm64 --arch x86_64`.
    swiftLanguageModes: [.v5]
)
