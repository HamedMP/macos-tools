import ArgumentParser
import Foundation
import SQLite

struct Email: Identifiable {
    let id: Int64
    let subject: String
    let sender: String
    let senderName: String?
    let date: Date
    let snippet: String
    let isRead: Bool
    let hasAttachments: Bool
    let mailbox: String
}

enum MailSortOrder: String, CaseIterable, ExpressibleByArgument {
    case date
    case sender
    case subject
}

class MailDatabase {
    private let db: Connection

    static func findDatabasePath() -> String? {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let mailDir = "\(home)/Library/Mail"

        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(atPath: mailDir) else {
            return nil
        }

        let vDirs = contents.filter { $0.hasPrefix("V") }.sorted().reversed()
        for vDir in vDirs {
            let dbPath = "\(mailDir)/\(vDir)/MailData/Envelope Index"
            if fileManager.fileExists(atPath: dbPath) {
                return dbPath
            }
        }
        return nil
    }

    init() throws {
        guard let path = Self.findDatabasePath() else {
            throw MailError.databaseNotFound
        }
        self.db = try Connection(path, readonly: true)
    }

    func listEmails(limit: Int = 20, sort: MailSortOrder = .date) throws -> [Email] {
        let orderBy: String
        switch sort {
        case .date: orderBy = "m.date_sent DESC"
        case .sender: orderBy = "a.address ASC, m.date_sent DESC"
        case .subject: orderBy = "s.subject ASC, m.date_sent DESC"
        }

        let query = """
            SELECT DISTINCT
                m.ROWID,
                s.subject,
                a.address,
                a.comment,
                m.date_sent,
                m.summary,
                m.read,
                m.flags,
                mb.url
            FROM messages m
            LEFT JOIN subjects s ON m.subject = s.ROWID
            LEFT JOIN senders sn ON m.sender = sn.ROWID
            LEFT JOIN sender_addresses sa ON sn.ROWID = sa.sender
            LEFT JOIN addresses a ON sa.address = a.ROWID
            LEFT JOIN mailboxes mb ON m.mailbox = mb.ROWID
            WHERE s.subject IS NOT NULL
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var emails: [Email] = []
        var seenIds = Set<Int64>()
        for row in try db.prepare(query, limit * 3) {
            if let id = row[0] as? Int64, !seenIds.contains(id) {
                seenIds.insert(id)
                emails.append(Email(
                    id: id,
                    subject: (row[1] as? String) ?? "(No Subject)",
                    sender: (row[2] as? String) ?? "",
                    senderName: row[3] as? String,
                    date: dateFromUnixTimestamp(row[4] as? Int64),
                    snippet: "",
                    isRead: (row[5] as? Int64 ?? 0) == 1,
                    hasAttachments: false,
                    mailbox: extractMailboxName(row[8] as? String)
                ))
                if emails.count >= limit { break }
            }
        }
        return emails
    }

    func searchEmails(query searchQuery: String, limit: Int = 50, sort: MailSortOrder = .date) throws -> [Email] {
        let searchPattern = "%\(searchQuery)%"
        let orderBy: String
        switch sort {
        case .date: orderBy = "m.date_sent DESC"
        case .sender: orderBy = "a.address ASC, m.date_sent DESC"
        case .subject: orderBy = "s.subject ASC, m.date_sent DESC"
        }

        let query = """
            SELECT DISTINCT
                m.ROWID,
                s.subject,
                a.address,
                a.comment,
                m.date_sent,
                m.read,
                mb.url
            FROM messages m
            LEFT JOIN subjects s ON m.subject = s.ROWID
            LEFT JOIN senders sn ON m.sender = sn.ROWID
            LEFT JOIN sender_addresses sa ON sn.ROWID = sa.sender
            LEFT JOIN addresses a ON sa.address = a.ROWID
            LEFT JOIN mailboxes mb ON m.mailbox = mb.ROWID
            WHERE s.subject IS NOT NULL
                AND (s.subject LIKE ? OR a.address LIKE ? OR a.comment LIKE ?)
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var emails: [Email] = []
        var seenIds = Set<Int64>()
        for row in try db.prepare(query, searchPattern, searchPattern, searchPattern, limit * 3) {
            if let id = row[0] as? Int64, !seenIds.contains(id) {
                seenIds.insert(id)
                emails.append(Email(
                    id: id,
                    subject: (row[1] as? String) ?? "(No Subject)",
                    sender: (row[2] as? String) ?? "",
                    senderName: row[3] as? String,
                    date: dateFromUnixTimestamp(row[4] as? Int64),
                    snippet: "",
                    isRead: (row[5] as? Int64 ?? 0) == 1,
                    hasAttachments: false,
                    mailbox: extractMailboxName(row[6] as? String)
                ))
                if emails.count >= limit { break }
            }
        }
        return emails
    }

    func unreadEmails(limit: Int = 50, sort: MailSortOrder = .date) throws -> [Email] {
        let orderBy: String
        switch sort {
        case .date: orderBy = "m.date_sent DESC"
        case .sender: orderBy = "a.address ASC, m.date_sent DESC"
        case .subject: orderBy = "s.subject ASC, m.date_sent DESC"
        }

        let query = """
            SELECT DISTINCT
                m.ROWID,
                s.subject,
                a.address,
                a.comment,
                m.date_sent,
                mb.url
            FROM messages m
            LEFT JOIN subjects s ON m.subject = s.ROWID
            LEFT JOIN senders sn ON m.sender = sn.ROWID
            LEFT JOIN sender_addresses sa ON sn.ROWID = sa.sender
            LEFT JOIN addresses a ON sa.address = a.ROWID
            LEFT JOIN mailboxes mb ON m.mailbox = mb.ROWID
            WHERE s.subject IS NOT NULL AND m.read = 0
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var emails: [Email] = []
        var seenIds = Set<Int64>()
        for row in try db.prepare(query, limit * 3) {
            if let id = row[0] as? Int64, !seenIds.contains(id) {
                seenIds.insert(id)
                emails.append(Email(
                    id: id,
                    subject: (row[1] as? String) ?? "(No Subject)",
                    sender: (row[2] as? String) ?? "",
                    senderName: row[3] as? String,
                    date: dateFromUnixTimestamp(row[4] as? Int64),
                    snippet: "",
                    isRead: false,
                    hasAttachments: false,
                    mailbox: extractMailboxName(row[5] as? String)
                ))
                if emails.count >= limit { break }
            }
        }
        return emails
    }

    func emailsFrom(sender: String, limit: Int = 50, sort: MailSortOrder = .date) throws -> [Email] {
        let senderPattern = "%\(sender)%"
        let orderBy: String
        switch sort {
        case .date: orderBy = "m.date_sent DESC"
        case .sender: orderBy = "a.address ASC, m.date_sent DESC"
        case .subject: orderBy = "s.subject ASC, m.date_sent DESC"
        }

        let query = """
            SELECT DISTINCT
                m.ROWID,
                s.subject,
                a.address,
                a.comment,
                m.date_sent,
                m.read,
                mb.url
            FROM messages m
            LEFT JOIN subjects s ON m.subject = s.ROWID
            LEFT JOIN senders sn ON m.sender = sn.ROWID
            LEFT JOIN sender_addresses sa ON sn.ROWID = sa.sender
            LEFT JOIN addresses a ON sa.address = a.ROWID
            LEFT JOIN mailboxes mb ON m.mailbox = mb.ROWID
            WHERE s.subject IS NOT NULL
                AND (a.address LIKE ? OR a.comment LIKE ?)
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var emails: [Email] = []
        var seenIds = Set<Int64>()
        for row in try db.prepare(query, senderPattern, senderPattern, limit * 3) {
            if let id = row[0] as? Int64, !seenIds.contains(id) {
                seenIds.insert(id)
                emails.append(Email(
                    id: id,
                    subject: (row[1] as? String) ?? "(No Subject)",
                    sender: (row[2] as? String) ?? "",
                    senderName: row[3] as? String,
                    date: dateFromUnixTimestamp(row[4] as? Int64),
                    snippet: "",
                    isRead: (row[5] as? Int64 ?? 0) == 1,
                    hasAttachments: false,
                    mailbox: extractMailboxName(row[6] as? String)
                ))
                if emails.count >= limit { break }
            }
        }
        return emails
    }

    func emailsWithAttachments(limit: Int = 50, sort: MailSortOrder = .date) throws -> [Email] {
        let orderBy: String
        switch sort {
        case .date: orderBy = "m.date_sent DESC"
        case .sender: orderBy = "a.address ASC, m.date_sent DESC"
        case .subject: orderBy = "s.subject ASC, m.date_sent DESC"
        }

        let query = """
            SELECT DISTINCT
                m.ROWID,
                s.subject,
                a.address,
                a.comment,
                m.date_sent,
                m.read,
                mb.url
            FROM messages m
            JOIN attachments att ON att.message = m.ROWID
            LEFT JOIN subjects s ON m.subject = s.ROWID
            LEFT JOIN senders sn ON m.sender = sn.ROWID
            LEFT JOIN sender_addresses sa ON sn.ROWID = sa.sender
            LEFT JOIN addresses a ON sa.address = a.ROWID
            LEFT JOIN mailboxes mb ON m.mailbox = mb.ROWID
            WHERE s.subject IS NOT NULL
            ORDER BY \(orderBy)
            LIMIT ?
        """

        var emails: [Email] = []
        var seenIds = Set<Int64>()
        for row in try db.prepare(query, limit * 3) {
            if let id = row[0] as? Int64, !seenIds.contains(id) {
                seenIds.insert(id)
                emails.append(Email(
                    id: id,
                    subject: (row[1] as? String) ?? "(No Subject)",
                    sender: (row[2] as? String) ?? "",
                    senderName: row[3] as? String,
                    date: dateFromUnixTimestamp(row[4] as? Int64),
                    snippet: "",
                    isRead: (row[5] as? Int64 ?? 0) == 1,
                    hasAttachments: true,
                    mailbox: extractMailboxName(row[6] as? String)
                ))
                if emails.count >= limit { break }
            }
        }
        return emails
    }

    private func dateFromUnixTimestamp(_ timestamp: Int64?) -> Date {
        guard let ts = timestamp else { return Date.distantPast }
        return Date(timeIntervalSince1970: Double(ts))
    }

    private func extractMailboxName(_ url: String?) -> String {
        guard let url = url else { return "" }
        if let lastSlash = url.lastIndex(of: "/") {
            return String(url[url.index(after: lastSlash)...])
        }
        return url
    }
}

enum MailError: Error, LocalizedError {
    case databaseNotFound
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Mail database not found. Make sure Mail app has been used and Full Disk Access is granted."
        case .sendFailed(let reason):
            return "Failed to send email: \(reason)"
        }
    }
}
