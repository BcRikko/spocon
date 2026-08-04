# spocon (minimal macOS menu bar app)

Made with AI.

このアプリケーションは、Spotifyアプリで再生中の「曲名」と「アーティスト名」をmacOSのメニューバー（タスクトレイ）に表示します。内部では `osascript`（AppleScript）でSpotifyから情報を取得し、再生中の曲情報を表示します。Spotifyが配信する `com.spotify.client.PlaybackStateChanged` 通知を利用してリアルタイムに更新し、5秒おきのポーリングをフォールバックとしています。

Small macOS status-bar (menu bar) app implemented as a Swift Package (AppKit).

**Requirements:**
- macOS 15+
- Swift 6 toolchain (SwiftPM)

**Quick build & run (debug)**
```bash
swift build
swift run
```

**Run tests**
```bash
swift test
```

**Create release .app bundle**
```bash
./Scripts/build_app.sh
```

This produces `.build/Release/spocon.app`. The script performs a release build, assembles the bundle, copies the included `Info.plist` and entitlements, and ad-hoc signs the app.

**Packaging & distribution notes**
- For public distribution you should sign with a Developer ID certificate and submit for notarization via Apple. Notarization requires an Apple Developer account and `notarytool`.
- Entitlements: the included `Packaging/spocon.entitlements` requests `com.apple.security.automation.apple-events` so the app can control/read Spotify via AppleScript.
- `Info.plist` sets `LSUIElement` to `true` so the app runs as a menu-bar-only (agent) app, and includes `NSAppleEventsUsageDescription` to explain the AppleScript usage to users.
- At runtime macOS may request Automation permission for `spocon` / `osascript`.

**Code / structure**
- `Package.swift` — package and executable named `spocon`, Swift 6 language mode
- `Sources/spocon/`
  - `App/` — `@main` entry point and `AppDelegate`
  - `Models/` — `NowPlaying`
  - `Services/` — `SpotifyClient`, `SpotifyStateParser`, `SpotifyPlaybackObserver`
  - `UI/` — `StatusItemController`, `MarqueeView`
  - `Utilities/` — `Constants`, `Logger`
- `Tests/spoconTests/` — unit tests for parsing and model logic
- `Packaging/` — `Info.plist` and entitlements template
- `Scripts/build_app.sh` — release .app bundle builder

**Runtime behavior**
- Menu-bar text shows now-playing as: `♪ {title} / {artist}`
- If text exceeds max width, a smooth marquee scroll is used (Core Animation). Default max width is defined in `Constants.UI.statusItemMaxWidth`.
- Spotify updates: listens to Spotify's distributed notification for state changes and refreshes every 5 seconds as a fallback.

**Troubleshooting**
- If AppleScript returns empty or permissions errors, open System Settings → Privacy & Security → Automation and allow `spocon` / `osascript` to control Spotify.

**Next steps for distribution**
- Sign with a Developer ID certificate and notarize before public distribution.
- Add a license file if you intend to publish.

See source files in `Sources/spocon/` for implementation details.
