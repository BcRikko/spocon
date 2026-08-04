import Testing
@testable import spocon

struct SpotifyStateParserTests {
    private let separator = "\u{001F}"

    @Test
    func parseNotRunning() {
        let output = ["false", "", "", ""].joined(separator: separator)
        let result = SpotifyStateParser.parse(output, separator: separator)
        #expect(result == .success(.notRunning))
    }

    @Test
    func parseStopped() {
        let output = ["true", "stopped", "", ""].joined(separator: separator)
        let result = SpotifyStateParser.parse(output, separator: separator)
        #expect(result == .success(.stopped))
    }

    @Test
    func parsePlaying() {
        let output = ["true", "playing", "Song Title", "Artist Name"].joined(separator: separator)
        let result = SpotifyStateParser.parse(output, separator: separator)
        #expect(result == .success(.playing(NowPlaying(title: "Song Title", artist: "Artist Name"))))
    }

    @Test
    func parsePaused() {
        let output = ["true", "paused", "Song Title", "Artist Name"].joined(separator: separator)
        let result = SpotifyStateParser.parse(output, separator: separator)
        #expect(result == .success(.paused(NowPlaying(title: "Song Title", artist: "Artist Name"))))
    }

    @Test
    func parseInvalidOutput() {
        let result = SpotifyStateParser.parse("not enough fields", separator: separator)
        #expect(result == .failure(.invalidOutput))
    }
}
