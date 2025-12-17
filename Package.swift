// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MyStatusBarApp",
    // 注意: 実行環境の SwiftPM によっては `.v14`/`.v15` が使えないため
    //       ローカルビルド互換性のため一時的に `.v11` を指定しています。
    //       意図する実行ターゲットは macOS Sequoia (v15) です。
    platforms: [
        .macOS(.v11)
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
