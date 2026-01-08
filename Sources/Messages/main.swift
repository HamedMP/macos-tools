import ArgumentParser
import Foundation

@main
struct MacMessages: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "mac-messages",
        abstract: "Fast CLI for iMessage",
        subcommands: [List.self, Search.self, History.self, Send.self],
        defaultSubcommand: List.self
    )
}

struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "List recent conversations"
    )

    @Option(name: .shortAndLong, help: "Number of conversations to show")
    var limit: Int = 20

    func run() throws {
        let db = try MessagesDatabase()
        let chats = try db.listChats(limit: limit)

        if chats.isEmpty {
            print("No conversations found.")
            return
        }

        printHeader("Recent Conversations")
        for chat in chats {
            printChat(chat)
        }
    }
}

struct Search: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Search messages"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Maximum results")
    var limit: Int = 50

    @Option(name: .shortAndLong, help: "Sort by: date, sender")
    var sort: SortOrder = .date

    func run() throws {
        let db = try MessagesDatabase()
        let messages = try db.searchMessages(query: query, limit: limit, sort: sort)

        if messages.isEmpty {
            print("No messages found matching '\(query)'.")
            return
        }

        printHeader("Search Results for '\(query)'")
        for message in messages {
            printMessage(message)
        }
        print("\nFound \(messages.count) message(s)")
    }
}

struct History: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Get message history with a contact"
    )

    @Argument(help: "Contact phone number, email, or name")
    var contact: String

    @Option(name: .shortAndLong, help: "Maximum messages")
    var limit: Int = 100

    @Option(name: .shortAndLong, help: "Sort by: date, sender")
    var sort: SortOrder = .date

    func run() throws {
        let db = try MessagesDatabase()
        let messages = try db.getHistory(contact: contact, limit: limit, sort: sort)

        if messages.isEmpty {
            print("No messages found with '\(contact)'.")
            return
        }

        printHeader("Messages with '\(contact)'")
        for message in messages {
            printMessage(message)
        }
        print("\nShowing \(messages.count) message(s)")
    }
}

struct Send: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Send an iMessage"
    )

    @Argument(help: "Recipient phone number or email")
    var recipient: String

    @Argument(help: "Message text")
    var message: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var yes: Bool = false

    func run() throws {
        print("To: \(recipient)")
        print("Message: \(message)")
        print("")

        if !yes {
            print("Send this message? [y/N] ", terminator: "")
            guard let response = readLine()?.lowercased(), response == "y" || response == "yes" else {
                print("Cancelled.")
                return
            }
        }

        print("Sending...")

        let script = """
        tell application "Messages"
            set targetService to 1st account whose service type = iMessage
            set targetBuddy to participant "\(escapeAppleScript(recipient))" of targetService
            send "\(escapeAppleScript(message))" to targetBuddy
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
            print("Message sent!")
        } else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorStr = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw MessagesError.sendFailed(errorStr)
        }
    }
}

// MARK: - Helpers

func printHeader(_ title: String) {
    print("\(title)")
    print(String(repeating: "-", count: 50))
}

func printChat(_ chat: Chat) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d"
    let dateStr = dateFormatter.string(from: chat.lastMessageDate)

    let displayName = chat.displayName.isEmpty ? chat.id : chat.displayName
    let participants = chat.participantCount > 1 ? " (\(chat.participantCount) people)" : ""

    print("  \(displayName)\(participants) - \(dateStr)")
    if !chat.lastMessage.isEmpty {
        let truncated = String(chat.lastMessage.prefix(60)).replacingOccurrences(of: "\n", with: " ")
        print("    \(truncated)")
    }
}

func printMessage(_ message: Message) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MMM d, HH:mm"
    let dateStr = dateFormatter.string(from: message.date)

    let sender = message.isFromMe ? "Me" : (message.senderPhone ?? "Unknown")
    let text = message.text.replacingOccurrences(of: "\n", with: " ")
    let truncated = String(text.prefix(80))

    print("  [\(dateStr)] \(sender): \(truncated)")
}

func escapeAppleScript(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
}
