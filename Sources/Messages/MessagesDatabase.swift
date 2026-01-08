import ArgumentParser
import Foundation
import SQLite

struct Message: Identifiable {
    let id: Int64
    let text: String
    let date: Date
    let isFromMe: Bool
    let chatId: String
    let senderName: String?
    let senderPhone: String?
}

struct Chat: Identifiable {
    let id: String
    let displayName: String
    let lastMessage: String
    let lastMessageDate: Date
    let participantCount: Int
}

enum SortOrder: String, CaseIterable, ExpressibleByArgument {
    case date
    case sender
}

class MessagesDatabase {
    private let db: Connection

    static let databasePath: String = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Messages/chat.db"
    }()

    init() throws {
        guard FileManager.default.fileExists(atPath: Self.databasePath) else {
            throw MessagesError.databaseNotFound
        }
        self.db = try Connection(Self.databasePath, readonly: true)
    }

    func listChats(limit: Int = 20) throws -> [Chat] {
        let query = """
            SELECT
                c.chat_identifier,
                c.display_name,
                m.text,
                m.date,
                (SELECT COUNT(*) FROM chat_handle_join WHERE chat_id = c.ROWID) as participant_count
            FROM chat c
            LEFT JOIN (
                SELECT cm.chat_id, m.text, m.date
                FROM chat_message_join cm
                JOIN message m ON cm.message_id = m.ROWID
                WHERE m.ROWID = (
                    SELECT MAX(m2.ROWID)
                    FROM chat_message_join cm2
                    JOIN message m2 ON cm2.message_id = m2.ROWID
                    WHERE cm2.chat_id = cm.chat_id
                )
            ) m ON m.chat_id = c.ROWID
            ORDER BY m.date DESC
            LIMIT ?
        """

        var chats: [Chat] = []
        for row in try db.prepare(query, limit) {
            if let chatId = row[0] as? String {
                chats.append(Chat(
                    id: chatId,
                    displayName: (row[1] as? String) ?? chatId,
                    lastMessage: (row[2] as? String) ?? "",
                    lastMessageDate: dateFromCocoaTimestamp(row[3] as? Int64),
                    participantCount: Int(row[4] as? Int64 ?? 1)
                ))
            }
        }
        return chats
    }

    func searchMessages(query searchQuery: String, limit: Int = 50, sort: SortOrder = .date) throws -> [Message] {
        let searchPattern = "%\(searchQuery)%"
        let orderBy = sort == .date ? "m.date DESC" : "h.id ASC, m.date DESC"

        let query = """
            SELECT
                m.ROWID,
                m.text,
                m.date,
                m.is_from_me,
                c.chat_identifier,
                h.id
            FROM message m
            JOIN chat_message_join cm ON cm.message_id = m.ROWID
            JOIN chat c ON cm.chat_id = c.ROWID
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.text LIKE ?
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var messages: [Message] = []
        for row in try db.prepare(query, searchPattern, limit) {
            if let id = row[0] as? Int64 {
                messages.append(Message(
                    id: id,
                    text: (row[1] as? String) ?? "",
                    date: dateFromCocoaTimestamp(row[2] as? Int64),
                    isFromMe: (row[3] as? Int64 ?? 0) == 1,
                    chatId: (row[4] as? String) ?? "",
                    senderName: nil,
                    senderPhone: row[5] as? String
                ))
            }
        }
        return messages
    }

    func getHistory(contact: String, limit: Int = 100, sort: SortOrder = .date) throws -> [Message] {
        let contactPattern = "%\(contact)%"
        let orderBy = sort == .date ? "m.date DESC" : "m.date ASC"

        let query = """
            SELECT
                m.ROWID,
                m.text,
                m.date,
                m.is_from_me,
                c.chat_identifier,
                h.id
            FROM message m
            JOIN chat_message_join cm ON cm.message_id = m.ROWID
            JOIN chat c ON cm.chat_id = c.ROWID
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE (c.chat_identifier LIKE ? OR c.display_name LIKE ? OR h.id LIKE ?)
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var messages: [Message] = []
        for row in try db.prepare(query, contactPattern, contactPattern, contactPattern, limit) {
            if let id = row[0] as? Int64 {
                messages.append(Message(
                    id: id,
                    text: (row[1] as? String) ?? "",
                    date: dateFromCocoaTimestamp(row[2] as? Int64),
                    isFromMe: (row[3] as? Int64 ?? 0) == 1,
                    chatId: (row[4] as? String) ?? "",
                    senderName: nil,
                    senderPhone: row[5] as? String
                ))
            }
        }
        return messages
    }

    private func dateFromCocoaTimestamp(_ timestamp: Int64?) -> Date {
        guard let ts = timestamp else { return Date.distantPast }
        // iMessage uses nanoseconds since 2001-01-01
        let seconds = Double(ts) / 1_000_000_000.0
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}

enum MessagesError: Error, LocalizedError {
    case databaseNotFound
    case sendFailed(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Messages database not found. Make sure Messages app has been used and Full Disk Access is granted."
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .cancelled:
            return "Operation cancelled."
        }
    }
}
