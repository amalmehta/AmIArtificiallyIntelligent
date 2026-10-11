// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "AmIArtificiallyIntelligent",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AmIArtificiallyIntelligent", targets: ["AmIArtificiallyIntelligent"]),
    ],
    targets: [
        .target(name: "QuizCore"),
        .target(name: "QuizUI", dependencies: ["QuizCore"]),
        .executableTarget(name: "AmIArtificiallyIntelligent", dependencies: ["QuizUI"]),
        .executableTarget(name: "ScreenshotRenderer", dependencies: ["QuizUI", "QuizCore"]),
        .testTarget(name: "QuizCoreTests", dependencies: ["QuizCore"]),
    ]
)
