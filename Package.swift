// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Scribo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Scribo",
            path: "Sources/Scribo"
        )
    ]
)
