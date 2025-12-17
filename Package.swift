// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyStatusBarApp",
    platforms: [
        .macOS(.v15) // macOS Sequoia 以上
    ],
    products: [
        .executable(name: "MyStatusBarApp", targets: ["MyStatusBarApp"]),
    ],
    targets: [
        .executableTarget(
            name: "MyStatusBarApp",
            path: "Sources/MyStatusBarApp"
        )
    ]
)
