import ArgumentParser
import Foundation

@main
struct MacMail: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mac-mail",
        abstract: "Fast CLI for Apple Mail",
        subcommands: [List.self, Search.self, Unread.self, From.self, Attachments.self, Send.self],
        defaultSubcommand: List.self
    )
}

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List recent emails"
    )

    @Option(name: .shortAndLong, help: "Number of emails to show")
    var limit: Int = 20

    @Option(name: .shortAndLong, help: "Sort by: date, sender, subject")
    var sort: MailSortOrder = .date

    func run() throws {
        let db = try MailDatabase()
        let emails = try db.listEmails(limit: limit, sort: sort)

        if emails.isEmpty {
            print("No emails found.")
            return
        }

        printHeader("Recent Emails")
        for email in emails {
            printEmail(email)
        }
    }
}

struct Search: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Search emails"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    @Option(name: .shortAndLong, help: "Sort by: date, sender, subject")
    var sort: MailSortOrder = .date

    func run() throws {
        let db = try MailDatabase()
        let emails = try db.searchEmails(query: query, limit: limit, sort: sort)

        if emails.isEmpty {
            print("No emails found matching '\(query)'.")
            return
        }

        printHeader("Search Results for '\(query)'")
        for email in emails {
            printEmail(email)
        }
        print("\nFound \(emails.count) email(s)")
    }
}

struct Unread: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Show unread emails"
    )

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    @Option(name: .shortAndLong, help: "Sort by: date, sender, subject")
    var sort: MailSortOrder = .date

    func run() throws {
        let db = try MailDatabase()
        let emails = try db.unreadEmails(limit: limit, sort: sort)

        if emails.isEmpty {
            print("No unread emails.")
            return
        }

        printHeader("Unread Emails")
        for email in emails {
            printEmail(email)
        }
        print("\n\(emails.count) unread email(s)")
    }
}

struct From: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Emails from a specific sender"
    )

    @Argument(help: "Sender email or name")
    var sender: String

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    @Option(name: .shortAndLong, help: "Sort by: date, sender, subject")
    var sort: MailSortOrder = .date

    func run() throws {
        let db = try MailDatabase()
        let emails = try db.emailsFrom(sender: sender, limit: limit, sort: sort)

        if emails.isEmpty {
            print("No emails found from '\(sender)'.")
            return
        }

        printHeader("Emails from '\(sender)'")
        for email in emails {
            printEmail(email)
        }
        print("\nFound \(emails.count) email(s)")
    }
}

struct Attachments: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Emails with attachments"
    )

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    @Option(name: .shortAndLong, help: "Sort by: date, sender, subject")
    var sort: MailSortOrder = .date

    func run() throws {
        let db = try MailDatabase()
        let emails = try db.emailsWithAttachments(limit: limit, sort: sort)

        if emails.isEmpty {
            print("No emails with attachments found.")
            return
        }

        printHeader("Emails with Attachments")
        for email in emails {
            printEmail(email)
        }
        print("\nFound \(emails.count) email(s) with attachments")
    }
}

struct Send: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Send an email"
    )

    @Option(name: .shortAndLong, help: "Recipient email address")
    var to: String

    @Option(name: .long, help: "Subject line")
    var subject: String

    @Option(name: .shortAndLong, help: "Email body")
    var body: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var yes: Bool = false

    func run() throws {
        print("To: \(to)")
        print("Subject: \(subject)")
        print("Body: \(body)")
        print("")

        if !yes {
            print("Send this email? [y/N] ", terminator: "")
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Cancelled.")
                return
            }
        }

        print("Sending...")

        let script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties {subject:"\(escapeAppleScript(subject))", content:"\(escapeAppleScript(body))", visible:false}
            tell newMessage
                make new to recipient at end of to recipients with properties {address:"\(escapeAppleScript(to))"}
            end tell
            send newMessage
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            print("Email sent!")
        } else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorStr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw MailError.sendFailed(errorStr)
        }
    }
}

// MARK: - Helpers

func printHeader(_ title: String) {
    print("\(title)")
    print(String(repeating: "-", count: 60))
}

func printEmail(_ email: Email) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    let dateStr = dateFormatter.string(from: email.date)

    let senderDisplay = email.senderName ?? email.sender
    let readIndicator = email.isRead ? " " : "*"
    let attachmentIndicator = email.hasAttachments ? " [+]" : ""

    print("\(readIndicator) [\(dateStr)] \(senderDisplay)\(attachmentIndicator)")
    print("    \(email.subject)")
    if !email.snippet.isEmpty {
        let truncated = String(email.snippet.prefix(70)).replacingOccurrences(of: "\n", with: " ")
        print("    \(truncated)...")
    }
}

func escapeAppleScript(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}
