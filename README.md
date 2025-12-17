# MyStatusBarApp (minimal macOS menu bar app)

Minimal scaffold: Swift Package that creates a macOS status bar (menu bar) app using AppKit.

Requirements
- macOS Sequoia (macOS 15)+ recommended
- Swift 5.5+

Build & Run
```bash
swift build
swift run
```

Notes
- The app sets `NSApp.setActivationPolicy(.accessory)` to avoid showing a Dock icon.
- For distribution you should create an Xcode project / .app bundle, set `CFBundleIdentifier`, and perform code signing and notarization.
