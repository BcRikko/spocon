import Cocoa

/// Clean single-definition StatusItemController + MarqueeView
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

    @objc private func buttonClicked(_ sender: Any?) {}
    @objc private func quit(_ sender: Any?) { NSApp.terminate(nil) }
}
