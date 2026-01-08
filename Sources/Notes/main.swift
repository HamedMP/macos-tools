import ArgumentParser
import Foundation

@main
struct MacNotes: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mac-notes",
        abstract: "Fast CLI for Apple Notes",
        subcommands: [List.self, Search.self, Folders.self, Export.self],
        defaultSubcommand: List.self
    )
}

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List recent notes"
    )

    @Option(name: .shortAndLong, help: "Number of notes to show")
    var limit: Int = 20

    func run() throws {
        let db = try NotesDatabase()
        let notes = try db.listNotes(limit: limit)

        if notes.isEmpty {
            print("No notes found.")
            return
        }

        printHeader("Recent Notes")
        for note in notes {
            printNote(note)
        }
    }
}

struct Search: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Search notes by title or content"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    func run() throws {
        let db = try NotesDatabase()
        let notes = try db.searchNotes(query: query, limit: limit)

        if notes.isEmpty {
            print("No notes found matching '\(query)'.")
            return
        }

        printHeader("Search Results for '\(query)'")
        for note in notes {
            printNote(note)
        }
        print("\nFound \(notes.count) note(s)")
    }
}

struct Folders: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List all folders"
    )

    func run() throws {
        let db = try NotesDatabase()
        let folders = try db.listFolders()

        if folders.isEmpty {
            print("No folders found.")
            return
        }

        printHeader("Folders")
        let maxNameLength = folders.map { $0.name.count }.max() ?? 20
        for folder in folders {
            let paddedName = folder.name.padding(toLength: maxNameLength + 2, withPad: " ", startingAt: 0)
            print("  \(paddedName) (\(folder.noteCount) notes)")
        }
    }
}

struct Export: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Export notes to markdown files"
    )

    @Option(name: .shortAndLong, help: "Output directory")
    var output: String = "~/notes-export"

    @Flag(name: .long, help: "Overwrite existing files")
    var overwrite: Bool = false

    func run() throws {
        let outputPath = NSString(string: output).expandingTildeInPath
        let fileManager = FileManager.default

        // Create output directory
        try fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true)

        print("Exporting notes to \(outputPath)...")
        print("Using AppleScript for full content export (this may take a moment)...\n")

        let script = """
        tell application "Notes"
            set noteCount to 0
            repeat with f in folders
                set folderName to name of f
                repeat with n in notes of f
                    set noteTitle to name of n
                    set noteBody to body of n
                    set noteCount to noteCount + 1
                    log "FOLDER:" & folderName & "|||TITLE:" & noteTitle & "|||BODY:" & noteBody & "|||END_NOTE"
                end repeat
            end repeat
            return noteCount
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

        var exportedCount = 0
        var folderCounts: [String: Int] = [:]

        // Parse the log output (notes are in stderr from osascript log)
        let notes = errorOutput.components(separatedBy: "|||END_NOTE")
        for noteEntry in notes {
            guard noteEntry.contains("FOLDER:") && noteEntry.contains("TITLE:") else { continue }

            var folderName = "Notes"
            var title = "Untitled"
            var body = ""

            // Extract folder
            if let folderRange = noteEntry.range(of: "FOLDER:"),
               let titleRange = noteEntry.range(of: "|||TITLE:") {
                folderName = String(noteEntry[folderRange.upperBound..<titleRange.lowerBound])
            }

            // Extract title
            if let titleRange = noteEntry.range(of: "|||TITLE:"),
               let bodyRange = noteEntry.range(of: "|||BODY:") {
                title = String(noteEntry[titleRange.upperBound..<bodyRange.lowerBound])
            }

            // Extract body
            if let bodyRange = noteEntry.range(of: "|||BODY:") {
                body = String(noteEntry[bodyRange.upperBound...])
            }

            // Sanitize folder and title for filesystem
            let safeFolder = sanitizeFilename(folderName)
            let safeTitle = sanitizeFilename(title)

            // Create folder
            let folderPath = "\(outputPath)/\(safeFolder)"
            try? fileManager.createDirectory(atPath: folderPath, withIntermediateDirectories: true)

            // Write note
            let filePath = "\(folderPath)/\(safeTitle).md"
            if !overwrite && fileManager.fileExists(atPath: filePath) {
                continue
            }

            // Convert HTML body to markdown-ish text
            let content = "# \(title)\n\n\(htmlToText(body))"
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)

            exportedCount += 1
            folderCounts[safeFolder, default: 0] += 1
        }

        print("Export complete!")
        print("  Total notes: \(exportedCount)")
        print("  Folders: \(folderCounts.count)")
        print("\nNotes by folder:")
        for (folder, count) in folderCounts.sorted(by: { $0.value > $1.value }) {
            print("  \(folder): \(count)")
        }
    }
}
