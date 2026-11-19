// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TalibTools",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "TalibTools",
            targets: ["TalibTools"]
        )
    ],
    targets: [
        .executableTarget(
            name: "TalibTools",
            path: "Sources/TalibTools"
        )
    ]
)
