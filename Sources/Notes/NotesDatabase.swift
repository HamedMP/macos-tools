import Foundation
import SQLite

struct Note: Identifiable {
    let id: Int64
    let title: String
    let snippet: String
    let folder: String
    let modifiedDate: Date
    let createdDate: Date
}

struct Folder {
    let name: String
    let noteCount: Int
}

class NotesDatabase {
    private let db: Connection

    static let databasePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite"
    }()

    init() throws {
        guard FileManager.default.fileExists(atPath: Self.databasePath) else {
            throw NotesError.databaseNotFound
        }
        self.db = try Connection(Self.databasePath, readonly: true)
    }

    func listNotes(limit: Int = 20) throws -> [Note] {
        let query = """
            SELECT
                n.Z_PK as id,
                n.ZTITLE1 as title,
                n.ZSNIPPET as snippet,
                f.ZTITLE2 as folder,
                n.ZMODIFICATIONDATE1 as modified,
                n.ZCREATIONDATE1 as created
            FROM ZICCLOUDSYNCINGOBJECT n
            LEFT JOIN ZICCLOUDSYNCINGOBJECT f ON n.ZFOLDER = f.Z_PK
            WHERE n.ZTITLE1 IS NOT NULL
                AND n.ZMARKEDFORDELETION != 1
            ORDER BY n.ZMODIFICATIONDATE1 DESC
            LIMIT ?
        """

        var notes: [Note] = []
        for row in try db.prepare(query, limit) {
            if let id = row[0] as? Int64,
               let title = row[1] as? String {
                notes.append(Note(
                    id: id,
                    title: title,
                    snippet: (row[2] as? String) ?? "",
                    folder: (row[3] as? String) ?? "Notes",
                    modifiedDate: dateFromCoreData(row[4] as? Double),
                    createdDate: dateFromCoreData(row[5] as? Double)
                ))
            }
        }
        return notes
    }

    func searchNotes(query searchQuery: String, limit: Int = 50) throws -> [Note] {
        let searchPattern = "%\(searchQuery)%"
        let query = """
            SELECT
                n.Z_PK as id,
                n.ZTITLE1 as title,
                n.ZSNIPPET as snippet,
                f.ZTITLE2 as folder,
                n.ZMODIFICATIONDATE1 as modified,
                n.ZCREATIONDATE1 as created
            FROM ZICCLOUDSYNCINGOBJECT n
            LEFT JOIN ZICCLOUDSYNCINGOBJECT f ON n.ZFOLDER = f.Z_PK
            WHERE n.ZTITLE1 IS NOT NULL
                AND n.ZMARKEDFORDELETION != 1
                AND (n.ZTITLE1 LIKE ? OR n.ZSNIPPET LIKE ?)
            ORDER BY n.ZMODIFICATIONDATE1 DESC
            LIMIT ?
        """

        var notes: [Note] = []
        for row in try db.prepare(query, searchPattern, searchPattern, limit) {
            if let id = row[0] as? Int64,
               let title = row[1] as? String {
                notes.append(Note(
                    id: id,
                    title: title,
                    snippet: (row[2] as? String) ?? "",
                    folder: (row[3] as? String) ?? "Notes",
                    modifiedDate: dateFromCoreData(row[4] as? Double),
                    createdDate: dateFromCoreData(row[5] as? Double)
                ))
            }
        }
        return notes
    }

    func listFolders() throws -> [Folder] {
        let query = """
            SELECT
                f.ZTITLE2 as folder,
                COUNT(n.Z_PK) as count
            FROM ZICCLOUDSYNCINGOBJECT f
            LEFT JOIN ZICCLOUDSYNCINGOBJECT n ON n.ZFOLDER = f.Z_PK AND n.ZTITLE1 IS NOT NULL AND n.ZMARKEDFORDELETION != 1
            WHERE f.ZTITLE2 IS NOT NULL
            GROUP BY f.ZTITLE2
            ORDER BY count DESC
        """

        var folders: [Folder] = []
        for row in try db.prepare(query) {
            if let name = row[0] as? String,
               let count = row[1] as? Int64 {
                folders.append(Folder(name: name, noteCount: Int(count)))
            }
        }
        return folders
    }

    func getNoteContent(id: Int64) throws -> String? {
        let query = """
            SELECT ZDATA
            FROM ZICNOTEDATA
            WHERE ZNOTE = ?
        """

        for row in try db.prepare(query, id) {
            if let data = row[0] as? SQLite.Blob {
                return extractTextFromNoteData(Data(data.bytes))
            }
        }
        return nil
    }

    private func dateFromCoreData(_ timestamp: Double?) -> Date {
        guard let ts = timestamp else { return Date.distantPast }
        // Core Data uses seconds since 2001-01-01
        return Date(timeIntervalSinceReferenceDate: ts)
    }

    private func extractTextFromNoteData(_ data: Data) -> String? {
        // Note content is gzipped - try to decompress
        guard let decompressed = try? decompress(data) else {
            return nil
        }
        // Extract readable text from the protobuf-like structure
        return extractReadableText(from: decompressed)
    }

    private func decompress(_ data: Data) throws -> Data {
        // Check for gzip magic number
        guard data.count > 2, data[0] == 0x1f, data[1] == 0x8b else {
            return data
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/gunzip")
        process.arguments = ["-c"]

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        inputPipe.fileHandleForWriting.write(data)
        inputPipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()

        return outputPipe.fileHandleForReading.readDataToEndOfFile()
    }

    private func extractReadableText(from data: Data) -> String {
        // Simple extraction: find UTF-8 text sequences
        var result = ""
        var currentString = ""

        for byte in data {
            if byte >= 0x20 && byte < 0x7f || byte == 0x0a || byte == 0x0d {
                currentString.append(Character(UnicodeScalar(byte)))
            } else if !currentString.isEmpty {
                if currentString.count > 3 {
                    result += currentString + " "
                }
                currentString = ""
            }
        }
        if currentString.count > 3 {
            result += currentString
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum NotesError: Error, LocalizedError {
    case databaseNotFound
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Apple Notes database not found. Make sure Notes app has been used on this Mac."
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}
