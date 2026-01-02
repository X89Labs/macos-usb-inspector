// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "USBInspector",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "USBInspector",
            targets: ["USBInspectorCLI"]
        ),
        .executable(
            name: "USBInspectorApp",
            targets: ["USBInspectorApp"]
        ),
        .library(
            name: "USBInspectorCore",
            targets: ["USBInspectorCore"]
        )
    ],
    targets: [
        .target(
            name: "USBInspectorCore",
            path: "Sources/USBInspectorCore"
        ),
        .executableTarget(
            name: "USBInspectorCLI",
            dependencies: ["USBInspectorCore"],
            path: "Sources/USBInspectorCLI"
        ),
        .executableTarget(
            name: "USBInspectorApp",
            dependencies: ["USBInspectorCore"],
            path: "Sources/USBInspectorApp"
        )
    ]
)
