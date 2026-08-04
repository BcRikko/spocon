import Testing
@testable import spocon

struct NowPlayingTests {
    @Test
    func equality() {
        let a = NowPlaying(title: "Song", artist: "Artist")
        let b = NowPlaying(title: "Song", artist: "Artist")
        #expect(a == b)
    }

    @Test
    func inequality() {
        let a = NowPlaying(title: "Song A", artist: "Artist")
        let b = NowPlaying(title: "Song B", artist: "Artist")
        #expect(a != b)
    }
}
