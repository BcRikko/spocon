import Cocoa

final class StatusItemController: NSObject {
    private var statusItem: NSStatusItem!

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                if let image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Status") {
                    image.isTemplate = true
                    button.image = image
                } else {
                    button.title = "⚙︎"
                }
            } else {
                button.title = "⚙︎"
            }
            button.action = #selector(buttonClicked(_:))
            button.target = self
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Quit", action: #selector(quit(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc private func buttonClicked(_ sender: Any?) {
        // menu is attached; clicking will show it automatically
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}
