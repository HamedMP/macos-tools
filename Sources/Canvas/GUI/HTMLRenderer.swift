import Foundation

class HTMLRenderer {
    private let calendarRenderer = CalendarRenderer()

    func render(_ document: ContentDocument) -> String {
        let rawMarkdown = document.rawMarkdown

        // Detect special content types
        if rawMarkdown.contains("# Email Preview") || rawMarkdown.contains("# Email Compose") {
            return renderEmailPreview(document)
        }

        // Live calendar with real data
        if rawMarkdown.contains("<!-- calendar:live") {
            let view = extractCalendarView(from: rawMarkdown)
            return calendarRenderer.renderLiveCalendar(view: view)
        }

        // Static calendar from markdown
        if rawMarkdown.contains("# Calendar") || rawMarkdown.contains("Schedule") {
            return renderCalendarView(document)
        }

        var html = ""
        for section in document.sections {
            html += renderSection(section)
        }

        return wrapWithStyles(html)
    }

    private func extractCalendarView(from markdown: String) -> String {
        if markdown.contains("calendar:live:week") {
            return "week"
        } else if markdown.contains("calendar:live:month") {
            return "month"
        }
        return "day"
    }

    // MARK: - Email Preview

    private func renderEmailPreview(_ document: ContentDocument) -> String {
        var from = "me"
        var to = ""
        var subject = ""
        var body = ""

        let markdown = document.rawMarkdown
        let lines = markdown.components(separatedBy: "\n")

        var inBody = false
        var bodyLines: [String] = []

        for line in lines {
            if line.contains("| From |") || line.contains("| To |") || line.contains("| Subject |") || line.contains("---") && line.contains("|") {
                continue
            }
            if line.contains("|") && line.lowercased().contains("from") {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 3 {
                    from = parts[2].trimmingCharacters(in: .whitespaces)
                }
            } else if line.contains("|") && line.lowercased().contains("to") {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 3 {
                    to = parts[2].trimmingCharacters(in: .whitespaces)
                }
            } else if line.contains("|") && line.lowercased().contains("subject") {
                let parts = line.components(separatedBy: "|")
                if parts.count >= 3 {
                    subject = parts[2].trimmingCharacters(in: .whitespaces)
                }
            } else if line == "---" {
                if !inBody && !to.isEmpty {
                    inBody = true
                } else if inBody {
                    break
                }
            } else if inBody && !line.starts(with: "**Actions") {
                bodyLines.append(line)
            }
        }

        body = bodyLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        let initials = String(from.prefix(2)).uppercased()
        let formattedBody = escapeHTML(body)
            .replacingOccurrences(of: "\n\n", with: "</p><p>")
            .replacingOccurrences(of: "\n", with: "<br>")

        let html = """
        <div class="email-container">
            <div class="email-header-bar">
                <div class="email-action-buttons">
                    <button class="email-btn" title="Send"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 2L11 13"/><path d="M22 2L15 22L11 13L2 9L22 2Z"/></svg></button>
                    <button class="email-btn" title="Attach"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/></svg></button>
                    <button class="email-btn" title="Discard"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg></button>
                </div>
                <div class="email-status">Draft</div>
            </div>

            <div class="email-compose">
                <div class="email-row">
                    <div class="avatar">\(initials)</div>
                    <div class="email-fields">
                        <div class="field-row">
                            <label>To</label>
                            <div class="field-value recipient">\(escapeHTML(to))</div>
                        </div>
                        <div class="field-row">
                            <label>Subject</label>
                            <div class="field-value subject">\(escapeHTML(subject))</div>
                        </div>
                    </div>
                </div>

                <div class="email-body-container">
                    <div class="email-body">
                        <p>\(formattedBody)</p>
                    </div>
                </div>

                <div class="email-signature">
                    <div class="sig-line"></div>
                    <p>Sent from mac-canvas</p>
                </div>
            </div>

            <div class="email-footer">
                <div class="shortcut-hint">
                    <kbd>E</kbd> Send via Mail.app
                    <kbd>Esc</kbd> Cancel
                </div>
            </div>
        </div>
        """

        return wrapWithStyles(html, extraStyles: emailStyles)
    }

    private var emailStyles: String {
        """
        .email-container {
            max-width: 700px;
            margin: 0 auto;
            background: var(--background);
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
        }

        .email-header-bar {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 16px;
            background: var(--accent);
            border-bottom: 1px solid rgba(0,0,0,0.1);
        }

        .email-action-buttons {
            display: flex;
            gap: 8px;
        }

        .email-btn {
            background: transparent;
            border: none;
            padding: 8px;
            border-radius: 6px;
            cursor: pointer;
            color: var(--dark);
            opacity: 0.7;
            transition: all 0.2s;
        }

        .email-btn:hover {
            background: rgba(0,0,0,0.1);
            opacity: 1;
        }

        .email-btn:first-child {
            background: var(--primary);
            color: white;
            opacity: 1;
        }

        .email-btn:first-child:hover {
            filter: brightness(1.1);
        }

        .email-status {
            font-size: 12px;
            color: var(--light-text);
            background: rgba(0,0,0,0.05);
            padding: 4px 10px;
            border-radius: 4px;
        }

        .email-compose {
            padding: 20px;
        }

        .email-row {
            display: flex;
            gap: 16px;
            margin-bottom: 20px;
        }

        .avatar {
            width: 44px;
            height: 44px;
            border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), #e6a089);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 14px;
            flex-shrink: 0;
        }

        .email-fields {
            flex: 1;
        }

        .field-row {
            display: flex;
            align-items: center;
            padding: 8px 0;
            border-bottom: 1px solid var(--accent);
        }

        .field-row label {
            width: 60px;
            color: var(--light-text);
            font-size: 13px;
        }

        .field-value {
            flex: 1;
            font-size: 14px;
        }

        .field-value.recipient {
            color: var(--primary);
            font-weight: 500;
        }

        .field-value.subject {
            font-weight: 600;
        }

        .email-body-container {
            min-height: 200px;
            padding: 16px;
            background: white;
            border-radius: 8px;
            margin: 16px 0;
        }

        @media (prefers-color-scheme: dark) {
            .email-body-container {
                background: #2a2a2a;
            }
        }

        .email-body {
            font-size: 14px;
            line-height: 1.7;
        }

        .email-body p {
            margin: 0 0 12px 0;
        }

        .email-signature {
            padding-top: 16px;
            color: var(--light-text);
            font-size: 12px;
        }

        .sig-line {
            height: 1px;
            background: var(--accent);
            margin-bottom: 12px;
        }

        .email-footer {
            padding: 16px;
            background: var(--accent);
            border-top: 1px solid rgba(0,0,0,0.05);
        }

        .shortcut-hint {
            display: flex;
            gap: 20px;
            justify-content: center;
            font-size: 12px;
            color: var(--light-text);
        }

        kbd {
            background: white;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: monospace;
            font-weight: 600;
            margin-right: 6px;
            box-shadow: 0 1px 2px rgba(0,0,0,0.1);
        }

        @media (prefers-color-scheme: dark) {
            kbd {
                background: #444;
            }
        }
        """
    }

    // MARK: - Calendar View

    private func renderCalendarView(_ document: ContentDocument) -> String {
        var events: [(time: String, title: String, duration: Int)] = []
        var dateTitle = "Today"
        var dateSubtitle = ""

        let markdown = document.rawMarkdown
        let lines = markdown.components(separatedBy: "\n")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        dateSubtitle = dateFormatter.string(from: Date())

        for line in lines {
            if line.starts(with: "# ") {
                dateTitle = String(line.dropFirst(2))
            }
            // Parse events: | 09:00 - 10:00 | Meeting Title |
            if line.contains("|") && line.contains(":") && !line.lowercased().contains("time") && !line.contains("---") {
                let parts = line.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if parts.count >= 2 {
                    let duration = parseEventDuration(parts[0])
                    events.append((time: parts[0], title: parts[1], duration: duration))
                }
            }
        }

        // Generate calendar grid
        var calendarHTML = """
        <div class="calendar-container">
            <div class="calendar-header">
                <div class="calendar-nav">
                    <button class="nav-btn">&lt;</button>
                    <div class="calendar-title">
                        <h1>\(escapeHTML(dateTitle))</h1>
                        <span class="date-subtitle">\(dateSubtitle)</span>
                    </div>
                    <button class="nav-btn">&gt;</button>
                </div>
                <div class="view-toggle">
                    <button class="view-btn active">Day</button>
                    <button class="view-btn">Week</button>
                    <button class="view-btn">Month</button>
                </div>
            </div>

            <div class="calendar-body">
                <div class="time-gutter">
        """

        // Time slots from 6am to 10pm
        for hour in 6...22 {
            let hourStr = hour < 12 ? "\(hour) AM" : (hour == 12 ? "12 PM" : "\(hour-12) PM")
            calendarHTML += "<div class=\"time-label\">\(hourStr)</div>"
        }

        calendarHTML += """
                </div>
                <div class="events-track">
                    <div class="hour-lines">
        """

        // Add hour lines
        for _ in 6...22 {
            calendarHTML += "<div class=\"hour-line\"></div>"
        }

        calendarHTML += """
                    </div>
                    <div class="events-layer">
        """

        // Place events
        let colors = ["#4285F4", "#EA4335", "#34A853", "#FBBC04", "#9C27B0", "#00BCD4"]
        for (index, event) in events.enumerated() {
            let position = parseTimeToPosition(event.time)
            let height = max(40, event.duration)
            let color = colors[index % colors.count]

            calendarHTML += """
            <div class="calendar-event" style="top: \(position)px; height: \(height)px; background: \(color);">
                <div class="event-content">
                    <div class="event-time">\(escapeHTML(event.time))</div>
                    <div class="event-title">\(escapeHTML(event.title))</div>
                </div>
            </div>
            """
        }

        calendarHTML += """
                    </div>
                </div>
            </div>

            <div class="calendar-footer">
                <div class="shortcut-hint">
                    Click on a time slot to add event
                </div>
            </div>
        </div>
        """

        return wrapWithStyles(calendarHTML, extraStyles: calendarStyles)
    }

    private func parseEventDuration(_ timeStr: String) -> Int {
        let parts = timeStr.components(separatedBy: " - ")
        guard parts.count == 2 else { return 60 }

        let startParts = parts[0].components(separatedBy: ":")
        let endParts = parts[1].components(separatedBy: ":")

        guard let startHour = Int(startParts[0]),
              let endHour = Int(endParts[0]) else { return 60 }

        let startMin = startParts.count > 1 ? (Int(startParts[1]) ?? 0) : 0
        let endMin = endParts.count > 1 ? (Int(endParts[1]) ?? 0) : 0

        return (endHour * 60 + endMin) - (startHour * 60 + startMin)
    }

    private func parseTimeToPosition(_ timeStr: String) -> Int {
        let parts = timeStr.components(separatedBy: " - ")
        let startTime = parts[0]
        let hourMin = startTime.components(separatedBy: ":")

        guard let hour = Int(hourMin[0]) else { return 0 }
        let min = hourMin.count > 1 ? (Int(hourMin[1]) ?? 0) : 0

        // Each hour is 60px, starting from 6am (position 0)
        return (hour - 6) * 60 + min
    }

    private var calendarStyles: String {
        """
        .calendar-container {
            background: var(--background);
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.1);
            margin: 10px;
        }

        .calendar-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 16px 20px;
            background: var(--accent);
            border-bottom: 1px solid rgba(0,0,0,0.1);
        }

        .calendar-nav {
            display: flex;
            align-items: center;
            gap: 16px;
        }

        .nav-btn {
            background: transparent;
            border: 1px solid var(--light-text);
            color: var(--dark);
            width: 32px;
            height: 32px;
            border-radius: 50%;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.2s;
        }

        .nav-btn:hover {
            background: var(--primary);
            border-color: var(--primary);
            color: white;
        }

        .calendar-title h1 {
            margin: 0;
            font-size: 20px;
            border: none;
            padding: 0;
        }

        .date-subtitle {
            font-size: 13px;
            color: var(--light-text);
        }

        .view-toggle {
            display: flex;
            gap: 4px;
            background: rgba(0,0,0,0.05);
            padding: 4px;
            border-radius: 8px;
        }

        .view-btn {
            background: transparent;
            border: none;
            padding: 6px 14px;
            border-radius: 6px;
            font-size: 13px;
            cursor: pointer;
            color: var(--dark);
            transition: all 0.2s;
        }

        .view-btn.active {
            background: white;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }

        @media (prefers-color-scheme: dark) {
            .view-btn.active {
                background: #444;
            }
        }

        .calendar-body {
            display: flex;
            height: 960px;
            overflow-y: auto;
        }

        .time-gutter {
            width: 70px;
            flex-shrink: 0;
            border-right: 1px solid var(--accent);
            padding-top: 10px;
        }

        .time-label {
            height: 60px;
            padding: 0 12px;
            font-size: 11px;
            color: var(--light-text);
            text-align: right;
        }

        .events-track {
            flex: 1;
            position: relative;
        }

        .hour-lines {
            position: absolute;
            inset: 0;
            padding-top: 10px;
        }

        .hour-line {
            height: 60px;
            border-bottom: 1px solid var(--accent);
        }

        .events-layer {
            position: absolute;
            inset: 0;
            padding: 10px 8px;
        }

        .calendar-event {
            position: absolute;
            left: 4px;
            right: 4px;
            border-radius: 6px;
            padding: 6px 10px;
            color: white;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
            overflow: hidden;
        }

        .calendar-event:hover {
            transform: scale(1.02);
            box-shadow: 0 4px 12px rgba(0,0,0,0.2);
        }

        .event-content {
            display: flex;
            flex-direction: column;
            gap: 2px;
        }

        .event-time {
            font-size: 11px;
            opacity: 0.9;
        }

        .event-title {
            font-size: 13px;
            font-weight: 500;
            line-height: 1.3;
        }

        .calendar-footer {
            padding: 12px;
            background: var(--accent);
            border-top: 1px solid rgba(0,0,0,0.05);
            text-align: center;
        }

        .shortcut-hint {
            font-size: 12px;
            color: var(--light-text);
        }
        """
    }

    // MARK: - Standard Rendering

    private func renderSection(_ section: Section) -> String {
        var html = ""

        if let title = section.title {
            switch section.type {
            case .heading(let level):
                html += "<h\(level)>\(escapeHTML(title))</h\(level)>\n"
            default:
                break
            }
        }

        for block in section.content {
            html += renderBlock(block)
        }

        return html
    }

    private func renderBlock(_ block: ContentBlock) -> String {
        switch block {
        case .text(let attr):
            return "<p>\(escapeHTML(attr.text))</p>\n"

        case .table(let table):
            return renderTable(table)

        case .codeBlock(let code, let language):
            let lang = language ?? ""
            return "<pre><code class=\"language-\(lang)\">\(escapeHTML(code))</code></pre>\n"

        case .list(let items):
            return renderList(items)

        case .checklist(let items):
            return renderChecklist(items)

        case .image(let alt, let url):
            return "<img src=\"\(escapeHTML(url))\" alt=\"\(escapeHTML(alt))\">\n"

        case .link(let text, let url):
            return "<a href=\"\(escapeHTML(url))\">\(escapeHTML(text))</a>\n"

        case .lineBreak:
            return "<hr>\n"
        }
    }

    private func renderTable(_ table: Table) -> String {
        var html = "<table>\n<thead><tr>\n"

        for header in table.headers {
            html += "<th>\(escapeHTML(header))</th>\n"
        }

        html += "</tr></thead>\n<tbody>\n"

        for row in table.rows {
            html += "<tr>\n"
            for cell in row {
                html += "<td>\(escapeHTML(cell))</td>\n"
            }
            html += "</tr>\n"
        }

        html += "</tbody>\n</table>\n"
        return html
    }

    private func renderList(_ items: [ListItem]) -> String {
        var html = "<ul>\n"
        for item in items {
            html += "<li>\(escapeHTML(item.content.text))"
            if !item.children.isEmpty {
                html += renderList(item.children)
            }
            html += "</li>\n"
        }
        html += "</ul>\n"
        return html
    }

    private func renderChecklist(_ items: [ChecklistItem]) -> String {
        var html = "<ul class=\"checklist\">\n"
        for item in items {
            let checked = item.isChecked ? "checked" : ""
            let className = item.isChecked ? "completed" : ""
            html += "<li class=\"\(className)\"><input type=\"checkbox\" \(checked) disabled> \(escapeHTML(item.content.text))</li>\n"
        }
        html += "</ul>\n"
        return html
    }

    private func escapeHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func wrapWithStyles(_ body: String, extraStyles: String = "") -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                :root {
                    --primary: #CC785C;
                    --dark: #191919;
                    --background: #FAF9F7;
                    --accent: #E8DDD4;
                    --light-text: #666666;
                    --green: #4ADE80;
                }

                @media (prefers-color-scheme: dark) {
                    :root {
                        --background: #1a1a1a;
                        --dark: #ffffff;
                        --accent: #333333;
                        --light-text: #999999;
                    }
                }

                * {
                    box-sizing: border-box;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;
                    background: var(--background);
                    color: var(--dark);
                    padding: 24px;
                    line-height: 1.6;
                    max-width: 100%;
                    margin: 0;
                }

                h1, h2, h3 {
                    color: var(--primary);
                    margin-top: 1.5em;
                    margin-bottom: 0.5em;
                }

                h1 { font-size: 1.8em; border-bottom: 2px solid var(--primary); padding-bottom: 8px; }
                h2 { font-size: 1.4em; }
                h3 { font-size: 1.2em; }

                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 16px 0;
                }

                th, td {
                    border: 1px solid var(--accent);
                    padding: 12px;
                    text-align: left;
                }

                th {
                    background: var(--accent);
                    font-weight: 600;
                }

                tr:nth-child(even) {
                    background: rgba(0,0,0,0.02);
                }

                pre {
                    background: #2d2d2d;
                    color: #ccc;
                    padding: 16px;
                    border-radius: 8px;
                    overflow-x: auto;
                }

                code {
                    font-family: 'SF Mono', Monaco, monospace;
                    font-size: 0.9em;
                }

                .checklist {
                    list-style: none;
                    padding-left: 0;
                }

                .checklist li {
                    padding: 8px 0;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }

                .checklist li.completed {
                    color: var(--light-text);
                    text-decoration: line-through;
                }

                .checklist input[type="checkbox"] {
                    width: 18px;
                    height: 18px;
                    accent-color: var(--green);
                }

                hr {
                    border: none;
                    border-top: 1px solid var(--accent);
                    margin: 24px 0;
                }

                a {
                    color: var(--primary);
                }

                blockquote {
                    border-left: 4px solid var(--primary);
                    padding-left: 16px;
                    margin-left: 0;
                    color: var(--light-text);
                    font-style: italic;
                }

                \(extraStyles)
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
