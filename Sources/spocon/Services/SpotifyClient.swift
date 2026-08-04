import Foundation

enum SpotifyError: Error, Equatable {
    case appleScriptFailed(String)
    case invalidOutput
}

enum PlaybackState: Sendable, Equatable {
    case notRunning
    case stopped
    case paused(NowPlaying)
    case playing(NowPlaying)
}

protocol SpotifyClient: Sendable {
    func fetchPlaybackState() async -> Result<PlaybackState, SpotifyError>
    func nextTrack() async
}

struct AppleScriptSpotifyClient: SpotifyClient {
    /// ASCII Unit Separator (0x1F). Must match the separator used in `fetchScript`.
    private static let fieldSeparator = "\u{001F}"

    func fetchPlaybackState() async -> Result<PlaybackState, SpotifyError> {
        do {
            let output = try await runAppleScript(Self.fetchScript)
            return SpotifyStateParser.parse(output, separator: Self.fieldSeparator)
        } catch let error as SpotifyError {
            return .failure(error)
        } catch {
            return .failure(.appleScriptFailed(error.localizedDescription))
        }
    }

    func nextTrack() async {
        _ = try? await runAppleScript(Self.nextTrackScript)
    }

    // MARK: - Scripts

    private static let fetchScript = #"""
    set sep to (ASCII character 31)
    tell application "System Events"
        set isRunning to (exists (processes where name is "Spotify"))
    end tell
    if not isRunning then
        return "false" & sep & "" & sep & "" & sep & ""
    end if
    tell application "Spotify"
        set state to player state as string
        if state is "stopped" then
            return "true" & sep & "stopped" & sep & "" & sep & ""
        end if
        set t to name of current track
        set a to artist of current track
        return "true" & sep & state & sep & t & sep & a
    end tell
    """#

    private static let nextTrackScript = #"""
    tell application "Spotify"
        next track
    end tell
    """#

    // MARK: - Execution

    private func runAppleScript(_ source: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let result = try Self.runAppleScriptSync(source)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func runAppleScriptSync(_ source: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "osascript exited with status \(process.terminationStatus)"
            throw SpotifyError.appleScriptFailed(errorMessage)
        }

        guard let output = String(data: outputData, encoding: .utf8) else {
            throw SpotifyError.invalidOutput
        }

        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
