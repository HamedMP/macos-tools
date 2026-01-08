import Foundation

struct CalendarEvent: Codable {
    let title: String
    let startDate: String
    let endDate: String
    let calendar: String
    let isAllDay: Bool
    let location: String?
    let notes: String?
    let url: String?
}

class CalendarRenderer {
    private var events: [CalendarEvent] = []
    private var currentView: String = "day"
    private var selectedDate: Date = Date()

    func renderLiveCalendar(view: String = "day") -> String {
        currentView = view
        fetchEvents()

        switch view {
        case "week":
            return renderWeekView()
        case "month":
            return renderMonthView()
        default:
            return renderDayView()
        }
    }

    private func fetchEvents() {
        let command: String
        switch currentView {
        case "week":
            command = "week"
        case "month":
            command = "month"
        default:
            command = ""
        }

        let possiblePaths = [
            "/opt/homebrew/bin/mac-calendar",
            "/usr/local/bin/mac-calendar"
        ]

        var calendarPath: String?
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                calendarPath = path
                break
            }
        }

        guard let path = calendarPath else {
            events = []
            return
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = command.isEmpty ? ["--json"] : [command, "--json"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            events = (try? JSONDecoder().decode([CalendarEvent].self, from: data)) ?? []
        } catch {
            events = []
        }
    }

    // MARK: - Day View

    private func renderDayView() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let dateTitle = dateFormatter.string(from: selectedDate)

        let todayEvents = filterEventsForDay(selectedDate)

        var html = """
        <div class="calendar-app" data-view="day">
            \(renderHeader(title: "Today", subtitle: dateTitle))
            <div class="calendar-body">
                <div class="time-gutter">
        """

        for hour in 0...23 {
            let hourStr = hour == 0 ? "12 AM" : (hour < 12 ? "\(hour) AM" : (hour == 12 ? "12 PM" : "\(hour-12) PM"))
            html += "<div class=\"time-label\">\(hourStr)</div>"
        }

        html += """
                </div>
                <div class="events-track">
                    <div class="hour-lines">
        """

        for hour in 0...23 {
            html += "<div class=\"hour-line\" data-hour=\"\(hour)\"></div>"
        }

        html += """
                    </div>
                    <div class="events-layer">
        """

        // Render all-day events banner
        let allDayEvents = todayEvents.filter { $0.isAllDay }
        if !allDayEvents.isEmpty {
            html += "<div class=\"all-day-banner\">"
            for event in allDayEvents {
                html += "<div class=\"all-day-event\">\(escapeHTML(event.title))</div>"
            }
            html += "</div>"
        }

        // Render timed events
        let timedEvents = todayEvents.filter { !$0.isAllDay }
        let colors = ["#4285F4", "#EA4335", "#34A853", "#FBBC04", "#9C27B0", "#00BCD4", "#FF5722", "#607D8B"]

        for (index, event) in timedEvents.enumerated() {
            let position = parseTimeToPosition(event.startDate)
            let duration = calculateDuration(start: event.startDate, end: event.endDate)
            let color = colors[index % colors.count]

            html += """
            <div class="calendar-event" style="top: \(position)px; height: \(max(30, duration))px; background: \(color);"
                 onclick="selectEvent('\(escapeHTML(event.title))')">
                <div class="event-content">
                    <div class="event-time">\(formatTimeRange(start: event.startDate, end: event.endDate))</div>
                    <div class="event-title">\(escapeHTML(event.title))</div>
                    \(event.location != nil ? "<div class=\"event-location\">\(escapeHTML(event.location!))</div>" : "")
                </div>
            </div>
            """
        }

        html += """
                    </div>
                    <div class="click-layer" onclick="handleTimeClick(event)"></div>
                </div>
            </div>
            \(renderFooter())
            \(renderEventDialog())
        </div>
        """

        return wrapWithStyles(html)
    }

    // MARK: - Week View

    private func renderWeekView() -> String {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
        let subtitle = "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))"

        var html = """
        <div class="calendar-app" data-view="week">
            \(renderHeader(title: "This Week", subtitle: subtitle))
            <div class="calendar-body week-view">
                <div class="time-gutter">
                    <div class="time-label header"></div>
        """

        for hour in 6...21 {
            let hourStr = hour < 12 ? "\(hour) AM" : (hour == 12 ? "12 PM" : "\(hour-12) PM")
            html += "<div class=\"time-label\">\(hourStr)</div>"
        }

        html += "</div>"

        // Render each day column
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let dateNumFormatter = DateFormatter()
        dateNumFormatter.dateFormat = "d"

        for dayOffset in 0..<7 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            let isToday = calendar.isDateInToday(day)
            let dayEvents = filterEventsForDay(day).filter { !$0.isAllDay }

            html += """
            <div class="day-column\(isToday ? " today" : "")">
                <div class="day-header">
                    <span class="day-name">\(dayFormatter.string(from: day))</span>
                    <span class="day-num\(isToday ? " current" : "")">\(dateNumFormatter.string(from: day))</span>
                </div>
                <div class="day-events">
                    <div class="hour-lines">
            """

            for hour in 6...21 {
                html += "<div class=\"hour-line\" data-hour=\"\(hour)\"></div>"
            }

            html += "</div><div class=\"events-layer\">"

            let colors = ["#4285F4", "#EA4335", "#34A853", "#FBBC04", "#9C27B0", "#00BCD4"]
            for (index, event) in dayEvents.enumerated() {
                let position = parseTimeToPosition(event.startDate) - (6 * 60) // Offset for 6am start
                let duration = calculateDuration(start: event.startDate, end: event.endDate)
                let color = colors[index % colors.count]

                if position >= 0 && position < (16 * 60) { // Only show events in visible range
                    html += """
                    <div class="calendar-event compact" style="top: \(position)px; height: \(max(20, min(duration, 16*60 - position)))px; background: \(color);">
                        <div class="event-title">\(escapeHTML(event.title))</div>
                    </div>
                    """
                }
            }

            html += "</div></div></div>"
        }

        html += """
            </div>
            \(renderFooter())
            \(renderEventDialog())
        </div>
        """

        return wrapWithStyles(html)
    }

    // MARK: - Month View

    private func renderMonthView() -> String {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthTitle = dateFormatter.string(from: monthStart)

        // Get first day of month and number of days
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let firstWeekday = calendar.component(.weekday, from: monthStart)

        var html = """
        <div class="calendar-app" data-view="month">
            \(renderHeader(title: monthTitle, subtitle: ""))
            <div class="calendar-body month-view">
                <div class="month-header">
                    <div class="weekday-label">Sun</div>
                    <div class="weekday-label">Mon</div>
                    <div class="weekday-label">Tue</div>
                    <div class="weekday-label">Wed</div>
                    <div class="weekday-label">Thu</div>
                    <div class="weekday-label">Fri</div>
                    <div class="weekday-label">Sat</div>
                </div>
                <div class="month-grid">
        """

        // Empty cells before first day
        for _ in 1..<firstWeekday {
            html += "<div class=\"day-cell empty\"></div>"
        }

        // Days of month
        for day in 1...range.count {
            let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
            let isToday = calendar.isDateInToday(dayDate)
            let dayEvents = filterEventsForDay(dayDate)

            html += """
            <div class="day-cell\(isToday ? " today" : "")" onclick="selectDate(\(day))">
                <div class="day-number\(isToday ? " current" : "")">\(day)</div>
                <div class="day-events-mini">
            """

            // Show up to 3 events
            for event in dayEvents.prefix(3) {
                let color = event.isAllDay ? "#9C27B0" : "#4285F4"
                html += "<div class=\"event-dot\" style=\"background: \(color);\" title=\"\(escapeHTML(event.title))\"></div>"
            }

            if dayEvents.count > 3 {
                html += "<div class=\"more-events\">+\(dayEvents.count - 3)</div>"
            }

            html += "</div></div>"
        }

        // Empty cells after last day
        let totalCells = (firstWeekday - 1) + range.count
        let remainingCells = (7 - (totalCells % 7)) % 7
        for _ in 0..<remainingCells {
            html += "<div class=\"day-cell empty\"></div>"
        }

        html += """
                </div>
            </div>
            \(renderFooter())
            \(renderEventDialog())
        </div>
        """

        return wrapWithStyles(html)
    }

    // MARK: - Components

    private func renderHeader(title: String, subtitle: String) -> String {
        """
        <div class="calendar-header">
            <div class="calendar-nav">
                <button class="nav-btn" onclick="navigate(-1)">&lt;</button>
                <div class="calendar-title">
                    <h1>\(escapeHTML(title))</h1>
                    \(subtitle.isEmpty ? "" : "<span class=\"date-subtitle\">\(escapeHTML(subtitle))</span>")
                </div>
                <button class="nav-btn" onclick="navigate(1)">&gt;</button>
            </div>
            <div class="view-toggle">
                <button class="view-btn\(currentView == "day" ? " active" : "")" onclick="switchView('day')">Day</button>
                <button class="view-btn\(currentView == "week" ? " active" : "")" onclick="switchView('week')">Week</button>
                <button class="view-btn\(currentView == "month" ? " active" : "")" onclick="switchView('month')">Month</button>
            </div>
        </div>
        """
    }

    private func renderFooter() -> String {
        """
        <div class="calendar-footer">
            <div class="shortcut-hint">
                Click on a time slot to add event | Data from macOS Calendar
            </div>
        </div>
        """
    }

    private func renderEventDialog() -> String {
        """
        <div id="eventDialog" class="event-dialog hidden">
            <div class="dialog-content">
                <div class="dialog-header">
                    <h2>New Event</h2>
                    <button class="close-btn" onclick="closeDialog()">&times;</button>
                </div>
                <div class="dialog-body">
                    <div class="form-group">
                        <label>Title</label>
                        <input type="text" id="eventTitle" placeholder="Event title">
                    </div>
                    <div class="form-group">
                        <label>Time</label>
                        <div class="time-inputs">
                            <input type="time" id="eventStart">
                            <span>to</span>
                            <input type="time" id="eventEnd">
                        </div>
                    </div>
                    <div class="form-group">
                        <label>Location</label>
                        <input type="text" id="eventLocation" placeholder="Add location">
                    </div>
                </div>
                <div class="dialog-footer">
                    <button class="btn-cancel" onclick="closeDialog()">Cancel</button>
                    <button class="btn-create" onclick="createEvent()">Add to Calendar</button>
                </div>
            </div>
        </div>
        """
    }

    // MARK: - Helpers

    private func filterEventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoFormatterAlt = ISO8601DateFormatter()
        isoFormatterAlt.formatOptions = [.withInternetDateTime]

        return events.filter { event in
            guard let eventStart = isoFormatter.date(from: event.startDate) ?? isoFormatterAlt.date(from: event.startDate) else {
                return false
            }
            return eventStart >= dayStart && eventStart < dayEnd
        }
    }

    private func parseTimeToPosition(_ dateStr: String) -> Int {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoFormatterAlt = ISO8601DateFormatter()
        isoFormatterAlt.formatOptions = [.withInternetDateTime]

        guard let date = isoFormatter.date(from: dateStr) ?? isoFormatterAlt.date(from: dateStr) else {
            return 0
        }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)

        return hour * 60 + minute
    }

    private func calculateDuration(start: String, end: String) -> Int {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoFormatterAlt = ISO8601DateFormatter()
        isoFormatterAlt.formatOptions = [.withInternetDateTime]

        guard let startDate = isoFormatter.date(from: start) ?? isoFormatterAlt.date(from: start),
              let endDate = isoFormatter.date(from: end) ?? isoFormatterAlt.date(from: end) else {
            return 60
        }

        return Int(endDate.timeIntervalSince(startDate) / 60)
    }

    private func formatTimeRange(start: String, end: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoFormatterAlt = ISO8601DateFormatter()
        isoFormatterAlt.formatOptions = [.withInternetDateTime]

        guard let startDate = isoFormatter.date(from: start) ?? isoFormatterAlt.date(from: start),
              let endDate = isoFormatter.date(from: end) ?? isoFormatterAlt.date(from: end) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    private func wrapWithStyles(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                \(baseStyles)
                \(calendarStyles)
                \(dialogStyles)
            </style>
            <script>
                \(interactionScript)
            </script>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    private var baseStyles: String {
        """
        :root {
            --primary: #4285F4;
            --dark: #191919;
            --background: #FAF9F7;
            --accent: #E8E8E8;
            --light-text: #666666;
            --border: #dadce0;
        }

        @media (prefers-color-scheme: dark) {
            :root {
                --background: #1a1a1a;
                --dark: #ffffff;
                --accent: #333333;
                --light-text: #999999;
                --border: #444;
            }
        }

        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
            background: var(--background);
            color: var(--dark);
            height: 100vh;
            overflow: hidden;
        }
        """
    }

    private var calendarStyles: String {
        """
        .calendar-app {
            display: flex;
            flex-direction: column;
            height: 100vh;
        }

        .calendar-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 20px;
            border-bottom: 1px solid var(--border);
            background: var(--background);
        }

        .calendar-nav {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .nav-btn {
            background: transparent;
            border: 1px solid var(--border);
            color: var(--dark);
            width: 32px;
            height: 32px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 14px;
        }

        .nav-btn:hover { background: var(--accent); }

        .calendar-title h1 {
            font-size: 20px;
            font-weight: 500;
        }

        .date-subtitle {
            font-size: 13px;
            color: var(--light-text);
        }

        .view-toggle {
            display: flex;
            gap: 4px;
            background: var(--accent);
            padding: 4px;
            border-radius: 8px;
        }

        .view-btn {
            background: transparent;
            border: none;
            padding: 6px 16px;
            border-radius: 6px;
            font-size: 13px;
            cursor: pointer;
            color: var(--dark);
        }

        .view-btn.active {
            background: var(--background);
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        .calendar-body {
            flex: 1;
            display: flex;
            overflow-y: auto;
        }

        .time-gutter {
            width: 60px;
            flex-shrink: 0;
            border-right: 1px solid var(--border);
        }

        .time-label {
            height: 60px;
            padding: 0 8px;
            font-size: 10px;
            color: var(--light-text);
            text-align: right;
        }

        .time-label.header { height: 50px; }

        .events-track {
            flex: 1;
            position: relative;
        }

        .hour-lines {
            position: absolute;
            inset: 0;
        }

        .hour-line {
            height: 60px;
            border-bottom: 1px solid var(--border);
            cursor: pointer;
        }

        .hour-line:hover { background: rgba(66, 133, 244, 0.05); }

        .events-layer {
            position: absolute;
            inset: 0;
            padding: 0 8px;
            pointer-events: none;
        }

        .events-layer .calendar-event { pointer-events: auto; }

        .click-layer {
            position: absolute;
            inset: 0;
            z-index: 1;
        }

        .calendar-event {
            position: absolute;
            left: 4px;
            right: 4px;
            border-radius: 4px;
            padding: 4px 8px;
            color: white;
            cursor: pointer;
            overflow: hidden;
            font-size: 12px;
            z-index: 2;
        }

        .calendar-event:hover {
            filter: brightness(1.1);
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        }

        .event-time { font-size: 10px; opacity: 0.9; }
        .event-title { font-weight: 500; line-height: 1.2; }
        .event-location { font-size: 10px; opacity: 0.8; margin-top: 2px; }

        .all-day-banner {
            display: flex;
            gap: 4px;
            padding: 4px 8px;
            background: var(--accent);
            border-bottom: 1px solid var(--border);
            flex-wrap: wrap;
        }

        .all-day-event {
            background: #9C27B0;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
        }

        /* Week View */
        .week-view { display: flex; }

        .day-column {
            flex: 1;
            border-right: 1px solid var(--border);
            position: relative;
        }

        .day-column.today { background: rgba(66, 133, 244, 0.03); }

        .day-header {
            height: 50px;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            border-bottom: 1px solid var(--border);
        }

        .day-name { font-size: 11px; color: var(--light-text); }
        .day-num { font-size: 20px; font-weight: 500; }
        .day-num.current {
            background: var(--primary);
            color: white;
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .day-events {
            position: relative;
            height: calc(16 * 60px);
        }

        .calendar-event.compact {
            padding: 2px 4px;
            font-size: 10px;
        }

        .calendar-event.compact .event-title {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        /* Month View */
        .month-view {
            flex-direction: column;
            padding: 16px;
        }

        .month-header {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            border-bottom: 1px solid var(--border);
            padding-bottom: 8px;
        }

        .weekday-label {
            text-align: center;
            font-size: 11px;
            font-weight: 500;
            color: var(--light-text);
        }

        .month-grid {
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            flex: 1;
        }

        .day-cell {
            min-height: 80px;
            border: 1px solid var(--border);
            border-top: none;
            border-left: none;
            padding: 4px;
            cursor: pointer;
        }

        .day-cell:hover { background: var(--accent); }
        .day-cell.today { background: rgba(66, 133, 244, 0.05); }
        .day-cell.empty { background: var(--accent); opacity: 0.5; }

        .day-number {
            font-size: 14px;
            font-weight: 500;
            margin-bottom: 4px;
        }

        .day-number.current {
            background: var(--primary);
            color: white;
            width: 24px;
            height: 24px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .day-events-mini {
            display: flex;
            flex-wrap: wrap;
            gap: 2px;
        }

        .event-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
        }

        .more-events {
            font-size: 10px;
            color: var(--light-text);
        }

        .calendar-footer {
            padding: 8px 16px;
            border-top: 1px solid var(--border);
            text-align: center;
        }

        .shortcut-hint {
            font-size: 11px;
            color: var(--light-text);
        }
        """
    }

    private var dialogStyles: String {
        """
        .event-dialog {
            position: fixed;
            inset: 0;
            background: rgba(0,0,0,0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 100;
        }

        .event-dialog.hidden { display: none; }

        .dialog-content {
            background: var(--background);
            border-radius: 12px;
            width: 400px;
            box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }

        .dialog-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
        }

        .dialog-header h2 {
            font-size: 18px;
            font-weight: 500;
        }

        .close-btn {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: var(--light-text);
        }

        .dialog-body { padding: 20px; }

        .form-group {
            margin-bottom: 16px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 500;
            color: var(--light-text);
            margin-bottom: 6px;
        }

        .form-group input {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--border);
            border-radius: 6px;
            font-size: 14px;
            background: var(--background);
            color: var(--dark);
        }

        .form-group input:focus {
            outline: none;
            border-color: var(--primary);
        }

        .time-inputs {
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .time-inputs input { width: auto; flex: 1; }
        .time-inputs span { color: var(--light-text); }

        .dialog-footer {
            display: flex;
            justify-content: flex-end;
            gap: 8px;
            padding: 16px 20px;
            border-top: 1px solid var(--border);
        }

        .btn-cancel, .btn-create {
            padding: 8px 16px;
            border-radius: 6px;
            font-size: 14px;
            cursor: pointer;
        }

        .btn-cancel {
            background: transparent;
            border: 1px solid var(--border);
            color: var(--dark);
        }

        .btn-create {
            background: var(--primary);
            border: none;
            color: white;
        }

        .btn-create:hover { filter: brightness(1.1); }
        """
    }

    private var interactionScript: String {
        """
        let selectedHour = null;
        let selectedDate = null;

        function handleTimeClick(e) {
            const rect = e.currentTarget.getBoundingClientRect();
            const y = e.clientY - rect.top;
            const hour = Math.floor(y / 60);
            selectedHour = hour;

            const now = new Date();
            document.getElementById('eventStart').value = `${hour.toString().padStart(2, '0')}:00`;
            document.getElementById('eventEnd').value = `${(hour + 1).toString().padStart(2, '0')}:00`;

            showDialog();
        }

        function selectEvent(title) {
            alert('Event: ' + title);
        }

        function selectDate(day) {
            selectedDate = day;
            const now = new Date();
            document.getElementById('eventStart').value = '09:00';
            document.getElementById('eventEnd').value = '10:00';
            showDialog();
        }

        function showDialog() {
            document.getElementById('eventDialog').classList.remove('hidden');
            document.getElementById('eventTitle').focus();
        }

        function closeDialog() {
            document.getElementById('eventDialog').classList.add('hidden');
            document.getElementById('eventTitle').value = '';
            document.getElementById('eventLocation').value = '';
        }

        function createEvent() {
            const title = document.getElementById('eventTitle').value;
            const start = document.getElementById('eventStart').value;
            const end = document.getElementById('eventEnd').value;
            const location = document.getElementById('eventLocation').value;

            if (!title) {
                alert('Please enter an event title');
                return;
            }

            // Send to Swift via webkit message handler if available
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.createEvent) {
                window.webkit.messageHandlers.createEvent.postMessage({
                    title: title,
                    start: start,
                    end: end,
                    location: location
                });
            } else {
                alert('Event created: ' + title + ' at ' + start + ' - ' + end);
            }

            closeDialog();
        }

        function switchView(view) {
            // Send message to reload with new view
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.switchView) {
                window.webkit.messageHandlers.switchView.postMessage(view);
            } else {
                alert('Switch to ' + view + ' view - requires app integration');
            }
        }

        function navigate(direction) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.navigate) {
                window.webkit.messageHandlers.navigate.postMessage(direction);
            }
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                closeDialog();
            }
        });
        """
    }
}
