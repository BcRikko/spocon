# spocon (minimal macOS menu bar app)

Made with AI.

このアプリケーションは、Spotifyアプリで再生中の「曲名」と「アーティスト名」をmacOSのメニューバー（タスクトレイ）に表示します。内部では `osascript`（AppleScript）でSpotifyから情報を取得し、再生中の曲情報を定期ポーリングして表示します。

Small macOS status-bar (menu bar) app implemented as a Swift Package (AppKit).

**Requirements:**
- macOS 11+ for local build compatibility (intended runtime: macOS 15+)
- Swift toolchain compatible with SwiftPM (local builds use macOS 11 target in Package.swift)

**Quick build & run (debug)**
```bash
swift build
swift run
```

**Create release .app bundle (manual, minimal steps)**
1. Build release binary:
```bash
swift build -c release
```
2. Create bundle structure and Info.plist (example; repository creates a basic plist during packaging):
```bash
mkdir -p .build/Release/spocon.app/Contents/MacOS
cp .build/arm64-apple-macosx/release/spocon .build/Release/spocon.app/Contents/MacOS/spocon
```
3. Ensure executable flag and ad-hoc codesign (for testing/distribution before proper signing):
```bash
chmod +x .build/Release/spocon.app/Contents/MacOS/spocon
codesign --force --sign - .build/Release/spocon.app
```
4. Zip for distribution:
```bash
zip -r spocon-macos.zip .build/Release/spocon.app
```

**Packaging & distribution notes**
- For public distribution you should sign with a Developer ID certificate and submit for notarization via Apple. Notarization requires an Apple Developer account and `altool` / `notarytool` usage.
- Entitlements: if you access protected APIs (e.g., AppleScript control of other apps), you may need to request appropriate entitlements and inform users about Accessibility / Automation permissions.
- The repository currently uses a simple AppleScript call (osascript) to poll Spotify. At runtime macOS may request Automation/Accessibility permission for `osascript`.

**Code / structure**
- Package: `Package.swift` (package and executable named `spocon`)
- Sources: `Sources/spocon/` (contains `main.swift`, `StatusItemController.swift`, `MarqueeView.swift`)
- App bundle example output: `.build/Release/spocon.app`

**Runtime behavior**
- Menu-bar text shows now-playing as: `♪ {title} / {artist}`
- If text exceeds max width, a smooth marquee scroll is used (Core Animation). Default max width is set inside `StatusItemController`.
- Spotify polling: implemented via `osascript` (AppleScript) executed periodically; adjust polling interval in `StatusItemController.startSpotifyUpdates(interval:)`.

**Troubleshooting**
- If build fails due to package description / platform mismatch, update your Xcode / Swift toolchain or adjust `platforms` in `Package.swift` to a compatible macOS version.
- If AppleScript returns empty or permissions errors, open System Settings → Privacy & Security → Automation/Accessibility and allow the required automation for Terminal / `osascript`.

**Next steps for distribution**
- Create an Xcode project or use `xcodebuild` to create an Xcode archive for proper code signing.
- Sign with Developer ID and notarize before public distribution.

**License**
- Add a license file if you intend to publish.

See source files in `Sources/spocon/` for implementation details.
