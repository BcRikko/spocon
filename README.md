# MyStatusBarApp (minimal macOS menu bar app)

Minimal scaffold: Swift Package that creates a macOS status bar (menu bar) app using AppKit.

Requirements
- Target runtime: macOS Sequoia (macOS 15)+ (intended runtime)
- Swift 5.5+

Note: ローカルの SwiftPM / Xcode ツールチェインが macOS 15 の PackageDescription をサポートしていない場合、`Package.swift` はローカルビルド互換のため `.macOS(.v11)` を指定しています。ビルド環境を macOS 15 対応（新しい Xcode / toolchain）に更新すると `Package.swift` のプラットフォームを `.macOS(.v15)` に戻してください（実行ターゲットは macOS Sequoia を想定しています）。

Build & Run
```bash
swift build
swift run
```

Notes
- The app sets `NSApp.setActivationPolicy(.accessory)` to avoid showing a Dock icon.
- For distribution you should create an Xcode project / .app bundle, set `CFBundleIdentifier`, and perform code signing and notarization.
