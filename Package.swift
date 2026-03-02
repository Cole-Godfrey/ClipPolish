// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipPolish",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ClipPolishCore",
            targets: ["ClipPolishCore"]
        ),
        .executable(
            name: "ClipPolishApp",
            targets: ["ClipPolishApp"]
        )
    ],
    targets: [
        .target(
            name: "ClipPolishCore",
            path: "Sources/ClipPolishCore"
        ),
        .executableTarget(
            name: "ClipPolishApp",
            dependencies: ["ClipPolishCore"],
            path: "Sources/ClipPolishApp"
        ),
        .testTarget(
            name: "ClipPolishCoreTests",
            dependencies: ["ClipPolishCore"],
            path: "Tests/ClipPolishCoreTests"
        ),
        .testTarget(
            name: "ClipPolishAppTests",
            dependencies: ["ClipPolishApp", "ClipPolishCore"],
            path: "Tests/ClipPolishAppTests"
        )
    ]
)
