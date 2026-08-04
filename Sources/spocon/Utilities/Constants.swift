import Foundation

enum Constants {
    enum UI {
        static let statusItemMaxWidth: CGFloat = 180
        static let statusItemMinWidth: CGFloat = 30
        static let statusItemPadding: CGFloat = 8
        static let marqueeSpeedPointsPerSecond: CGFloat = 30
        static let marqueeStartDelay: TimeInterval = 1.0
        static let marqueeEndDelay: TimeInterval = 2.0
    }

    enum Spotify {
        static let playbackStateChangedNotification = "com.spotify.client.PlaybackStateChanged"
        static let refreshInterval: TimeInterval = 5.0
        static let autoSkipThreshold: TimeInterval = 100
    }

    enum MenuItemTag: Int {
        case title = 1
        case artist = 2
        case autoSkip = 3
    }

    enum Menu {
        static let titlePlaceholder = "♪ (no title)"
        static let artistPlaceholder = "● (no artist)"
        static let noTitle = "(no title)"
        static let noArtist = "(no artist)"
        static let autoSkipTitle = "Auto Skip (100s)"
        static let quitTitle = "Quit"
    }

    enum Animation {
        static let marqueeKey = "marquee.translation"
    }
}
