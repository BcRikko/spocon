import Cocoa

@MainActor
final class StatusItemController: NSObject {
    private let client: any SpotifyClient
    private let observer: SpotifyPlaybackObserver

    private var statusItem: NSStatusItem?
    private var marqueeView: MarqueeView?
    private var maxWidthPoints: CGFloat = Constants.UI.statusItemMaxWidth

    private var currentTitle: String = ""
    private var currentArtist: String = ""
    private var currentIsPlaying: Bool = false
    private var accumulatedPlaySeconds: TimeInterval = 0
    private var lastPollDate: Date?
    private var isAutoSkipEnabled: Bool = false

    init(client: any SpotifyClient = AppleScriptSpotifyClient()) {
        self.client = client
        self.observer = SpotifyPlaybackObserver(client: client)
        super.init()
        self.observer.onUpdate = { [weak self] state in
            self?.handleSpotifyUpdate(state)
        }
    }

    func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.menu = makeMenu()
        item.menu?.delegate = self
        statusItem = item

        setText("initializing…", maxWidth: nil)
        observer.start()
    }

    func tearDown() {
        observer.stop()
    }

    // MARK: - Spotify state handling

    private func handleSpotifyUpdate(_ state: PlaybackState) {
        let now = Date()
        defer { lastPollDate = now }

        switch state {
        case .notRunning, .stopped:
            resetCurrentState()
            setText("Spotify is not running", maxWidth: nil)

        case .paused(let nowPlaying):
            updateTrack(nowPlaying, isPlaying: false, at: now)

        case .playing(let nowPlaying):
            updateTrack(nowPlaying, isPlaying: true, at: now)

            if isAutoSkipEnabled, accumulatedPlaySeconds >= Constants.Spotify.autoSkipThreshold {
                Task {
                    await client.nextTrack()
                }
                accumulatedPlaySeconds = 0
            }
        }
    }

    private func updateTrack(_ nowPlaying: NowPlaying, isPlaying: Bool, at now: Date) {
        let trackChanged = nowPlaying.title != currentTitle || nowPlaying.artist != currentArtist
        if trackChanged {
            accumulatedPlaySeconds = 0
        }

        if isPlaying, let last = lastPollDate {
            accumulatedPlaySeconds += now.timeIntervalSince(last)
        }

        currentTitle = nowPlaying.title
        currentArtist = nowPlaying.artist
        currentIsPlaying = isPlaying

        guard !nowPlaying.title.isEmpty else {
            setText("loading…", maxWidth: nil)
            return
        }

        setNowPlaying(music: nowPlaying.title, artist: nowPlaying.artist, maxWidth: nil)
    }

    private func resetCurrentState() {
        currentTitle = ""
        currentArtist = ""
        currentIsPlaying = false
        accumulatedPlaySeconds = 0
    }

    // MARK: - UI

    func setText(_ text: String, maxWidth: CGFloat?) {
        if let maxWidth { maxWidthPoints = maxWidth }
        guard let button = statusItem?.button else { return }

        let desiredWidth = computeDesiredWidth(
            text: text,
            font: button.font,
            padding: Constants.UI.statusItemPadding
        )
        statusItem?.length = desiredWidth

        let itemHeight = NSStatusBar.system.thickness

        if let existingView = marqueeView {
            existingView.frame = NSRect(x: 0, y: 0, width: desiredWidth, height: itemHeight)
        } else {
            let view = MarqueeView(frame: NSRect(x: 0, y: 0, width: desiredWidth, height: itemHeight))
            view.autoresizingMask = [.height]
            button.addSubview(view)
            marqueeView = view
        }

        marqueeView?.setText(text, containerWidth: desiredWidth, font: button.font)
    }

    func setNowPlaying(music: String, artist: String, maxWidth: CGFloat? = nil) {
        let formatted = "♪ \(music) / \(artist)"
        setText(formatted, maxWidth: maxWidth)
    }

    // MARK: - Menu actions

    @objc private func toggleAutoSkip(_ sender: Any?) {
        isAutoSkipEnabled.toggle()
        if let item = sender as? NSMenuItem {
            item.state = isAutoSkipEnabled ? .on : .off
        }
    }

    @objc private func copyTitle(_ sender: Any?) {
        guard !currentTitle.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentTitle, forType: .string)
    }

    @objc private func copyArtist(_ sender: Any?) {
        guard !currentArtist.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentArtist, forType: .string)
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    // MARK: - Helpers

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let titleItem = NSMenuItem(
            title: Constants.Menu.titlePlaceholder,
            action: #selector(copyTitle(_:)),
            keyEquivalent: ""
        )
        titleItem.tag = Constants.MenuItemTag.title.rawValue
        titleItem.target = self
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        let artistItem = NSMenuItem(
            title: Constants.Menu.artistPlaceholder,
            action: #selector(copyArtist(_:)),
            keyEquivalent: ""
        )
        artistItem.tag = Constants.MenuItemTag.artist.rawValue
        artistItem.target = self
        artistItem.isEnabled = false
        menu.addItem(artistItem)

        menu.addItem(.separator())

        let autoSkipItem = NSMenuItem(
            title: Constants.Menu.autoSkipTitle,
            action: #selector(toggleAutoSkip(_:)),
            keyEquivalent: ""
        )
        autoSkipItem.tag = Constants.MenuItemTag.autoSkip.rawValue
        autoSkipItem.target = self
        autoSkipItem.state = isAutoSkipEnabled ? .on : .off
        menu.addItem(autoSkipItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: Constants.Menu.quitTitle,
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func computeDesiredWidth(text: String, font: NSFont?, padding: CGFloat) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        ]
        let measuredWidth = NSString(string: text).size(withAttributes: attributes).width
        return min(maxWidthPoints, max(Constants.UI.statusItemMinWidth, measuredWidth + padding))
    }
}

extension StatusItemController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        if let titleItem = menu.item(withTag: Constants.MenuItemTag.title.rawValue) {
            titleItem.title = "♪ " + (currentTitle.isEmpty ? Constants.Menu.noTitle : currentTitle)
            titleItem.isEnabled = !currentTitle.isEmpty
        }
        if let artistItem = menu.item(withTag: Constants.MenuItemTag.artist.rawValue) {
            artistItem.title = "● " + (currentArtist.isEmpty ? Constants.Menu.noArtist : currentArtist)
            artistItem.isEnabled = !currentArtist.isEmpty
        }
        if let autoSkipItem = menu.item(withTag: Constants.MenuItemTag.autoSkip.rawValue) {
            autoSkipItem.state = isAutoSkipEnabled ? .on : .off
        }
    }
}
