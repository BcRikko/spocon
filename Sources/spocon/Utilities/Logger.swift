import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "dev.spocon"

    static let spotify = Logger(subsystem: subsystem, category: "Spotify")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
