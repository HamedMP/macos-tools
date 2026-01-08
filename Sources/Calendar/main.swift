import EventKit
import Foundation

let store = EKEventStore()

func requestAccess() async -> Bool {
    if #available(macOS 14.0, *) {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    } else {
        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }
}

func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

func formatFullDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d, yyyy"
    return formatter.string(from: date)
}

func getEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
    let calendars = store.calendars(for: .event)
    let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
    return store.events(matching: predicate).sorted { $0.startDate < $1.startDate }
}

func printEvents(_ events: [EKEvent], title: String, showJson: Bool) {
    if showJson {
        printEventsAsJson(events)
        return
    }

    print(title)
    print(String(repeating: "-", count: 50))

    if events.isEmpty {
        print("No events scheduled.")
        return
    }

    var currentDay = ""
    let dayFormatter = DateFormatter()
    dayFormatter.dateFormat = "EEEE, MMM d"

    for event in events {
        let eventDay = dayFormatter.string(from: event.startDate)

        if eventDay != currentDay {
            if !currentDay.isEmpty { print() }
            print("\(eventDay)")
            currentDay = eventDay
        }

        let timeStr: String
        if event.isAllDay {
            timeStr = "All day  "
        } else {
            timeStr = "\(formatTime(event.startDate)) - \(formatTime(event.endDate))"
        }

        let calendar = event.calendar.title
        print("  \(timeStr) | \(event.title ?? "Untitled") [\(calendar)]")
    }
}

func printEventsAsJson(_ events: [EKEvent]) {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime]

    var jsonEvents: [[String: Any]] = []

    for event in events {
        var dict: [String: Any] = [
            "title": event.title ?? "Untitled",
            "calendar": event.calendar.title,
            "isAllDay": event.isAllDay,
            "startDate": isoFormatter.string(from: event.startDate),
            "endDate": isoFormatter.string(from: event.endDate)
        ]

        if let location = event.location, !location.isEmpty {
            dict["location"] = location
        }

        if let notes = event.notes, !notes.isEmpty {
            dict["notes"] = notes
        }

        if let url = event.url {
            dict["url"] = url.absoluteString
        }

        jsonEvents.append(dict)
    }

    if let jsonData = try? JSONSerialization.data(withJSONObject: jsonEvents, options: .prettyPrinted),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
    }
}

func printUsage() {
    print("""
    mac-calendar - Query macOS Calendar from the command line

    USAGE:
        mac-calendar [RANGE] [OPTIONS]

    RANGE:
        today       Today's events (default)
        tomorrow    Tomorrow's events
        week        Next 7 days
        month       Next 30 days

    OPTIONS:
        --json      Output as JSON
        --help      Show this help

    EXAMPLES:
        mac-calendar                 # Today's events
        mac-calendar tomorrow        # Tomorrow's events
        mac-calendar week --json     # This week as JSON
    """)
}

@main
struct CalendarCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let showJson = args.contains("--json")
        let range = args.first { !$0.hasPrefix("-") } ?? "today"

        let granted = await requestAccess()
        guard granted else {
            fputs("Error: Calendar access denied.\n", stderr)
            fputs("Grant access in: System Settings > Privacy & Security > Calendars\n", stderr)
            exit(1)
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let startDate: Date
        let endDate: Date
        let title: String

        switch range.lowercased() {
        case "today":
            startDate = startOfToday
            endDate = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            title = "Today - \(formatFullDate(now))"

        case "tomorrow":
            startDate = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            endDate = calendar.date(byAdding: .day, value: 2, to: startOfToday)!
            title = "Tomorrow - \(formatFullDate(startDate))"

        case "week":
            startDate = startOfToday
            endDate = calendar.date(byAdding: .day, value: 7, to: startOfToday)!
            title = "This Week"

        case "month":
            startDate = startOfToday
            endDate = calendar.date(byAdding: .day, value: 30, to: startOfToday)!
            title = "Next 30 Days"

        default:
            fputs("Unknown range: \(range)\n", stderr)
            printUsage()
            exit(1)
        }

        let events = getEvents(from: startDate, to: endDate)
        printEvents(events, title: title, showJson: showJson)
    }
}
