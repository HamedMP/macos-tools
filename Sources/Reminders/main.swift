import EventKit
import Foundation

let store = EKEventStore()

func requestAccess() async -> Bool {
    if #available(macOS 14.0, *) {
        do {
            return try await store.requestFullAccessToReminders()
        } catch {
            return false
        }
    } else {
        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .reminder) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
    return await withCheckedContinuation { continuation in
        store.fetchReminders(matching: predicate) { reminders in
            continuation.resume(returning: reminders ?? [])
        }
    }
}

func formatDate(_ date: Date?) -> String {
    guard let date = date else { return "" }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, HH:mm"
    return formatter.string(from: date)
}

func listReminders(completed: Bool = false) async {
    let calendars = store.calendars(for: .reminder)
    let predicate = store.predicateForReminders(in: calendars)
    let reminders = await fetchReminders(matching: predicate)

    let filtered = reminders
        .filter { $0.isCompleted == completed }
        .sorted {
            let d1 = $0.dueDateComponents?.date ?? .distantFuture
            let d2 = $1.dueDateComponents?.date ?? .distantFuture
            return d1 < d2
        }

    if filtered.isEmpty {
        print(completed ? "No completed reminders." : "No pending reminders.")
        return
    }

    let title = completed ? "Completed Reminders" : "Pending Reminders"
    print(title)
    print(String(repeating: "-", count: 50))

    var currentList = ""
    for reminder in filtered {
        let listName = reminder.calendar.title
        if listName != currentList {
            if !currentList.isEmpty { print() }
            print("[\(listName)]")
            currentList = listName
        }

        let status = reminder.isCompleted ? "[x]" : "[ ]"
        var dueStr = ""
        if let dueDate = reminder.dueDateComponents?.date {
            dueStr = " (due: \(formatDate(dueDate)))"
        }
        let priority = reminder.priority > 0 ? " !" : ""
        print("  \(status) \(reminder.title ?? "Untitled")\(priority)\(dueStr)")
    }
}

func listRemindersJson() async {
    let calendars = store.calendars(for: .reminder)
    let predicate = store.predicateForReminders(in: calendars)
    let reminders = await fetchReminders(matching: predicate)

    let isoFormatter = ISO8601DateFormatter()
    var jsonReminders: [[String: Any]] = []

    for reminder in reminders {
        var dict: [String: Any] = [
            "title": reminder.title ?? "Untitled",
            "list": reminder.calendar.title,
            "completed": reminder.isCompleted,
            "priority": reminder.priority
        ]
        if let dueDate = reminder.dueDateComponents?.date {
            dict["dueDate"] = isoFormatter.string(from: dueDate)
        }
        if let notes = reminder.notes, !notes.isEmpty {
            dict["notes"] = notes
        }
        jsonReminders.append(dict)
    }

    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonReminders, options: .prettyPrinted),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
}

func printUsage() {
    print("""
    mac-reminders - Query macOS Reminders

    USAGE:
        mac-reminders [COMMAND] [OPTIONS]

    COMMANDS:
        list        List pending reminders (default)
        completed   List completed reminders
        all         List all reminders

    OPTIONS:
        --json      Output as JSON
        --help      Show this help

    EXAMPLES:
        mac-reminders              # List pending reminders
        mac-reminders completed    # List completed
        mac-reminders --json       # JSON output
    """)
}

@main
struct RemindersCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let granted = await requestAccess()
        guard granted else {
            fputs("Error: Reminders access denied.\n", stderr)
            fputs("Grant access in: System Settings > Privacy & Security > Reminders\n", stderr)
            exit(1)
        }

        let showJson = args.contains("--json")
        let command = args.first { !$0.hasPrefix("-") } ?? "list"

        if showJson {
            await listRemindersJson()
            return
        }

        switch command {
        case "list":
            await listReminders(completed: false)
        case "completed":
            await listReminders(completed: true)
        case "all":
            await listReminders(completed: false)
            print()
            await listReminders(completed: true)
        default:
            await listReminders(completed: false)
        }
    }
}
