import Cocoa

/// Simple container for now-playing info
public struct NowPlaying {
    public let music: String
    public let artist: String
    public init(music: String, artist: String) {
        self.music = music
        self.artist = artist
    }
}

/// Clean single-definition StatusItemController
final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem!
    private var marqueeView: MarqueeView?
    private var maxWidthPoints: CGFloat = 200
    private var spotifyTimer: DispatchSourceTimer?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(buttonClicked(_:))
            button.target = self
        }

        let menu = NSMenu()
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        setText("♪ 曲名-------------------------/------------------アーティスト", maxWidth: nil)

        // start polling Spotify for now-playing info
        startSpotifyUpdates()
    }

    // MARK: - Spotify integration
    /// Start periodic polling of Spotify (every `interval` seconds)
    func startSpotifyUpdates(interval: TimeInterval = 2.0) {
        stopSpotifyUpdates()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + 0.5, repeating: interval)
        timer.setEventHandler { [weak self] in
            self?.fetchSpotifyNowPlaying()
        }
        timer.resume()
        spotifyTimer = timer
    }

    func stopSpotifyUpdates() {
        spotifyTimer?.cancel()
        spotifyTimer = nil
    }

    private func fetchSpotifyNowPlaying() {
        // AppleScript: return "title||artist" or empty string
        let script = #"""
tell application "System Events"
    set isRunning to (exists (processes where name is "Spotify"))
end tell
if not isRunning then
    return ""
end if
tell application "Spotify"
    if player state is playing then
        set t to name of current track
        set a to artist of current track
        return t & "||" & a
    else
        return ""
    end if
end tell
"""#

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments = ["-e", script]
        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = Pipe()

        do {
            try proc.run()
        } catch {
            return
        }
        proc.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard var s = String(data: data, encoding: .utf8) else { return }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty {
            // clear display when not playing
            DispatchQueue.main.async { [weak self] in
                self?.setText("", maxWidth: nil)
            }
            return
        }

        let parts = s.components(separatedBy: "||")
        let title = parts.first ?? ""
        let artist = parts.dropFirst().first ?? ""

        DispatchQueue.main.async { [weak self] in
            self?.setNowPlaying(music: title, artist: artist, maxWidth: nil)
        }
    }

    func setText(_ text: String, maxWidth: CGFloat?) {
        if let mw = maxWidth { maxWidthPoints = mw }
        guard let button = statusItem.button else { return }

        statusItem.length = maxWidthPoints

        if marqueeView == nil {
            marqueeView = MarqueeView(frame: NSRect(x: 0, y: 0, width: maxWidthPoints, height: button.bounds.height))
            marqueeView?.autoresizingMask = [.height]
            button.addSubview(marqueeView!)
        } else {
            marqueeView?.frame = NSRect(x: 0, y: 0, width: maxWidthPoints, height: button.bounds.height)
        }

        marqueeView?.setText(text, containerWidth: maxWidthPoints, font: button.font)
    }

    /// Set now-playing info using separate fields
    func setNowPlaying(music: String, artist: String, maxWidth: CGFloat? = nil) {
        let formatted = "♪ \(music) / \(artist)"
        setText(formatted, maxWidth: maxWidth)
    }

    /// Set now-playing info using `NowPlaying` struct
    func setNowPlaying(_ info: NowPlaying, maxWidth: CGFloat? = nil) {
        setNowPlaying(music: info.music, artist: info.artist, maxWidth: maxWidth)
    }

    /// Set now-playing info from a dictionary-like payload (e.g. {"music":"...","artist":"..."})
    func setNowPlaying(from dict: [String: String], maxWidth: CGFloat? = nil) {
        let music = dict["music"] ?? ""
        let artist = dict["artist"] ?? ""
        setNowPlaying(music: music, artist: artist, maxWidth: maxWidth)
    }

    @objc private func buttonClicked(_ sender: Any?) {}
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }
}
