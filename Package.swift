// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ArabicHelper",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ArabicHelper",
            targets: ["ArabicHelper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "ArabicHelper",
            path: "Sources/ArabicHelper"
        )
    ]
)
