import Foundation

func runAppleScript(_ script: String) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}

func getNowPlaying() {
    // Try Apple Music first
    let musicScript = """
    tell application "Music"
        if player state is playing then
            set trackName to name of current track
            set artistName to artist of current track
            set albumName to album of current track
            return "Music|" & trackName & "|" & artistName & "|" & albumName
        else
            return "Music|stopped"
        end if
    end tell
    """

    // Try Spotify
    let spotifyScript = """
    tell application "Spotify"
        if player state is playing then
            set trackName to name of current track
            set artistName to artist of current track
            set albumName to album of current track
            return "Spotify|" & trackName & "|" & artistName & "|" & albumName
        else
            return "Spotify|stopped"
        end if
    end tell
    """

    var found = false

    if let result = runAppleScript(musicScript), !result.contains("stopped") {
        let parts = result.components(separatedBy: "|")
        if parts.count >= 4 {
            print("Now Playing (Apple Music)")
            print(String(repeating: "-", count: 50))
            print("  \(parts[1])")
            print("  \(parts[2]) - \(parts[3])")
            found = true
        }
    }

    if !found, let result = runAppleScript(spotifyScript), !result.contains("stopped") {
        let parts = result.components(separatedBy: "|")
        if parts.count >= 4 {
            print("Now Playing (Spotify)")
            print(String(repeating: "-", count: 50))
            print("  \(parts[1])")
            print("  \(parts[2]) - \(parts[3])")
            found = true
        }
    }

    if !found {
        print("Nothing playing.")
    }
}

func controlPlayback(_ action: String) {
    let musicScript = """
    tell application "Music"
        \(action)
    end tell
    """

    let spotifyScript = """
    tell application "Spotify"
        \(action)
    end tell
    """

    // Try both apps
    _ = runAppleScript(musicScript)
    _ = runAppleScript(spotifyScript)

    print("\(action.capitalized) executed.")
}

func printUsage() {
    print("""
    mac-music - Control Apple Music / Spotify

    USAGE:
        mac-music [COMMAND]

    COMMANDS:
        now         Show now playing (default)
        play        Start playback
        pause       Pause playback
        next        Next track
        prev        Previous track

    EXAMPLES:
        mac-music           # What's playing?
        mac-music play      # Start playing
        mac-music next      # Skip to next track
    """)
}

@main
struct MusicCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let command = args.first ?? "now"

        switch command {
        case "now", "playing":
            getNowPlaying()
        case "play":
            controlPlayback("play")
        case "pause", "stop":
            controlPlayback("pause")
        case "next", "skip":
            controlPlayback("next track")
        case "prev", "previous", "back":
            controlPlayback("previous track")
        default:
            getNowPlaying()
        }
    }
}
