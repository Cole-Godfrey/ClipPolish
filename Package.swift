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
        )
    ],
    targets: [
        .target(
            name: "ClipPolishCore",
            path: "Sources/ClipPolishCore"
        ),
        .testTarget(
            name: "ClipPolishCoreTests",
            dependencies: ["ClipPolishCore"],
            path: "Tests/ClipPolishCoreTests"
        )
    ]
)
