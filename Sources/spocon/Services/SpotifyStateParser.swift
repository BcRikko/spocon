import Foundation

enum SpotifyStateParser {
    static func parse(_ output: String, separator: String) -> Result<PlaybackState, SpotifyError> {
        let fields = output.components(separatedBy: separator)
        guard fields.count >= 4 else {
            return .failure(.invalidOutput)
        }

        let isRunning = fields[0] == "true"
        let state = fields[1]
        let title = fields[2]
        let artist = fields[3]

        guard isRunning else {
            return .success(.notRunning)
        }

        guard state != "stopped" else {
            return .success(.stopped)
        }

        let nowPlaying = NowPlaying(title: title, artist: artist)
        return state == "playing"
            ? .success(.playing(nowPlaying))
            : .success(.paused(nowPlaying))
    }
}
