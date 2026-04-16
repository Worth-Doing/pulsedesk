// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PulseDesk",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "PulseDesk",
            path: "Sources/PulseDesk",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("Metal"),
            ]
        )
    ]
)
