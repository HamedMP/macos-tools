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

func listNotes(limit: Int = 20) {
    let script = """
    tell application "Notes"
        set noteList to ""
        set noteCount to 0
        repeat with f in folders
            repeat with n in notes of f
                if noteCount < \(limit) then
                    set noteList to noteList & name of n & " | " & name of f & " | " & (modification date of n as string) & linefeed
                    set noteCount to noteCount + 1
                end if
            end repeat
        end repeat
        return noteList
    end tell
    """

    guard let result = runAppleScript(script), !result.isEmpty else {
        print("No notes found or Notes app not accessible.")
        return
    }

    print("Recent Notes")
    print(String(repeating: "-", count: 50))

    for line in result.components(separatedBy: "\n") where !line.isEmpty {
        let parts = line.components(separatedBy: " | ")
        if parts.count >= 2 {
            let title = parts[0]
            let folder = parts[1]
            print("  \(title) [\(folder)]")
        }
    }
}

func searchNotes(query: String) {
    let escapedQuery = query.replacingOccurrences(of: "\"", with: "\\\"")
    let script = """
    tell application "Notes"
        set results to ""
        set searchQuery to "\(escapedQuery)"
        repeat with f in folders
            repeat with n in notes of f
                if name of n contains searchQuery or body of n contains searchQuery then
                    set results to results & name of n & " | " & name of f & linefeed
                end if
            end repeat
        end repeat
        return results
    end tell
    """

    guard let result = runAppleScript(script), !result.isEmpty else {
        print("No notes found matching '\(query)'")
        return
    }

    print("Search Results for '\(query)'")
    print(String(repeating: "-", count: 50))

    for line in result.components(separatedBy: "\n") where !line.isEmpty {
        let parts = line.components(separatedBy: " | ")
        if parts.count >= 2 {
            print("  \(parts[0]) [\(parts[1])]")
        }
    }
}

func listFolders() {
    let script = """
    tell application "Notes"
        set folderList to ""
        repeat with f in folders
            set folderList to folderList & name of f & " (" & (count of notes of f) & " notes)" & linefeed
        end repeat
        return folderList
    end tell
    """

    guard let result = runAppleScript(script), !result.isEmpty else {
        print("No folders found.")
        return
    }

    print("Note Folders")
    print(String(repeating: "-", count: 50))

    for line in result.components(separatedBy: "\n") where !line.isEmpty {
        print("  \(line)")
    }
}

func printUsage() {
    print("""
    mac-notes - Query macOS Notes

    USAGE:
        mac-notes [COMMAND] [OPTIONS]

    COMMANDS:
        list            List recent notes (default)
        search <query>  Search notes by title or content
        folders         List all folders

    OPTIONS:
        --limit N       Limit results (default: 20)
        --help          Show this help

    EXAMPLES:
        mac-notes                    # List recent notes
        mac-notes search meeting     # Search for 'meeting'
        mac-notes folders            # List folders
    """)
}

@main
struct NotesCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let command = args.first { !$0.hasPrefix("-") } ?? "list"

        switch command {
        case "list":
            listNotes()
        case "search":
            if let idx = args.firstIndex(of: "search"), idx + 1 < args.count {
                let query = args[idx + 1]
                searchNotes(query: query)
            } else {
                print("Usage: mac-notes search <query>")
            }
        case "folders":
            listFolders()
        default:
            listNotes()
        }
    }
}
