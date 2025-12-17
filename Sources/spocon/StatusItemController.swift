import Cocoa

public struct NowPlaying {
    public let music: String
    public let artist: String
    public init(music: String, artist: String) {
        self.music = music
        self.artist = artist
    }
}

final class StatusItemController: NSObject, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var marqueeView: MarqueeView?
    private var maxWidthPoints: CGFloat = 180
    private var spotifyTimer: DispatchSourceTimer?
    private var currentTitle: String = ""
    private var currentArtist: String = ""

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // let the system display the menu; update its contents just before it opens
        if let button = statusItem.button {
            button.target = self
        }

        let menu = makeMenu()
        menu.delegate = self
        statusItem.menu = menu

        setText("initializing...", maxWidth: nil)
        startSpotifyUpdates()
    }

    // MARK: - Spotify polling
    func startSpotifyUpdates(interval: TimeInterval = 2.0) {
        stopSpotifyUpdates()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
        timer.schedule(deadline: .now() + 0.5, repeating: interval)
        timer.setEventHandler { [weak self] in self?.fetchSpotifyNowPlaying() }
        timer.resume()
        spotifyTimer = timer
    }

    func stopSpotifyUpdates() {
        spotifyTimer?.cancel()
        spotifyTimer = nil
    }

    private func fetchSpotifyNowPlaying() {
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

        do { try proc.run() } catch { return }
        proc.waitUntilExit()

        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        guard var s = String(data: data, encoding: .utf8) else { return }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty {
            DispatchQueue.main.async { [weak self] in self?.setText("loading...", maxWidth: nil) }
            return
        }

        let parts = s.components(separatedBy: "||")
        let title = parts.first ?? ""
        let artist = parts.dropFirst().first ?? ""

        DispatchQueue.main.async { [weak self] in
            self?.setNowPlaying(music: title, artist: artist, maxWidth: nil)
        }
    }

    // MARK: - UI
    func setText(_ text: String, maxWidth: CGFloat?) {
        if let mw = maxWidth { maxWidthPoints = mw }
        guard let button = statusItem.button else { return }

        let desiredWidth = computeDesiredWidth(text: text, font: button.font, padding: 8)
        statusItem.length = desiredWidth

        if marqueeView == nil {
            marqueeView = MarqueeView(frame: NSRect(x: 0, y: 0, width: desiredWidth, height: button.bounds.height))
            marqueeView?.autoresizingMask = [.height]
            button.addSubview(marqueeView!)
        } else {
            marqueeView?.frame = NSRect(x: 0, y: 0, width: desiredWidth, height: button.bounds.height)
        }

        marqueeView?.setText(text, containerWidth: desiredWidth, font: button.font)
    }

    func setNowPlaying(music: String, artist: String, maxWidth: CGFloat? = nil) {
        currentTitle = music
        currentArtist = artist
        let formatted = "♪ \(music) / \(artist)"
        setText(formatted, maxWidth: maxWidth)
    }

    func setNowPlaying(_ info: NowPlaying, maxWidth: CGFloat? = nil) {
        setNowPlaying(music: info.music, artist: info.artist, maxWidth: maxWidth)
    }

    func setNowPlaying(from dict: [String: String], maxWidth: CGFloat? = nil) {
        let music = dict["music"] ?? ""
        let artist = dict["artist"] ?? ""
        setNowPlaying(music: music, artist: artist, maxWidth: maxWidth)
    }

    @objc private func buttonClicked(_ sender: Any?) {}
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }

    // MARK: - Menu delegate
    func menuWillOpen(_ menu: NSMenu) {
        // find title / artist items by tag and update their titles
        if let titleItem = menu.item(withTag: 1) {
            titleItem.title = "♪ " + (currentTitle.isEmpty ? "(no title)" : currentTitle)
            titleItem.isEnabled = !currentTitle.isEmpty
        }
        if let artistItem = menu.item(withTag: 2) {
            artistItem.title = "● " + (currentArtist.isEmpty ? "(no artist)" : currentArtist)
            artistItem.isEnabled = !currentArtist.isEmpty
        }
    }

    @objc private func copyTitle(_ sender: Any?) {
        guard !currentTitle.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(currentTitle, forType: .string)
    }

    @objc private func copyArtist(_ sender: Any?) {
        guard !currentArtist.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(currentArtist, forType: .string)
    }

    // MARK: - Helpers
    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(title: "♪ (no title)", action: #selector(copyTitle(_:)), keyEquivalent: "")
        titleItem.tag = 1
        titleItem.target = self
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let artistItem = NSMenuItem(title: "● (no artist)", action: #selector(copyArtist(_:)), keyEquivalent: "")
        artistItem.tag = 2
        artistItem.target = self
        artistItem.isEnabled = false
        menu.addItem(artistItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func computeDesiredWidth(text: String, font: NSFont?, padding: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font as Any]
        let measuredTextWidth = NSString(string: text).size(withAttributes: attrs).width
        return min(maxWidthPoints, max(30, measuredTextWidth + padding))
    }
}
