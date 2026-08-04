// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "spocon",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "spocon", targets: ["spocon"]),
    ],
    targets: [
        .executableTarget(
            name: "spocon",
            path: "Sources/spocon",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "spoconTests",
            dependencies: ["spocon"],
            path: "Tests/spoconTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
