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

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(buttonClicked(_:))
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        statusItem.menu = menu

        setText("♪ 曲名-------------------------/------------------アーティスト", maxWidth: nil)
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
