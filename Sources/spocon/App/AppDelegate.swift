import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusController = StatusItemController()
        statusController?.setup()
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusController?.tearDown()
    }
}
