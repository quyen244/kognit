// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kognit",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "Kognit",
            targets: ["Kognit"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Kognit",
            dependencies: [],
            path: "Kognit"
        ),
        .testTarget(
            name: "KognitTests",
            dependencies: ["Kognit"],
            path: "Tests"
        )
    ]
)
