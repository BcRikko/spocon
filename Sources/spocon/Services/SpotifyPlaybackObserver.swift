import Foundation
import OSLog

@MainActor
final class SpotifyPlaybackObserver: NSObject {
    private let client: any SpotifyClient
    private let notificationCenter: DistributedNotificationCenter
    private var timer: Timer?

    var onUpdate: (@MainActor (PlaybackState) -> Void)?

    init(
        client: any SpotifyClient,
        notificationCenter: DistributedNotificationCenter = DistributedNotificationCenter.default()
    ) {
        self.client = client
        self.notificationCenter = notificationCenter
        super.init()
    }

    func start() {
        stop()

        notificationCenter.addObserver(
            self,
            selector: #selector(handlePlaybackStateChanged),
            name: Notification.Name(Constants.Spotify.playbackStateChangedNotification),
            object: nil
        )

        timer = Timer.scheduledTimer(
            timeInterval: Constants.Spotify.refreshInterval,
            target: self,
            selector: #selector(handleTimerFired),
            userInfo: nil,
            repeats: true
        )

        Task {
            await refresh()
        }
    }

    func stop() {
        notificationCenter.removeObserver(self)
        timer?.invalidate()
        timer = nil
    }

    @objc private func handlePlaybackStateChanged() {
        Task {
            await refresh()
        }
    }

    @objc private func handleTimerFired() {
        Task {
            await refresh()
        }
    }

    private func refresh() async {
        let result = await client.fetchPlaybackState()
        switch result {
        case .success(let state):
            onUpdate?(state)
        case .failure(let error):
            Logger.spotify.error("Failed to fetch playback state: \(error.localizedDescription, privacy: .public)")
        }
    }
}
