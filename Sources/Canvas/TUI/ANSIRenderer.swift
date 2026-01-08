import Foundation

class ANSIRenderer {
    // Claude Code brand colors (approximated for terminal)
    let primary = ANSI.rgb(r: 204, g: 120, b: 92)      // Terracotta #CC785C
    let accent = ANSI.rgb(r: 232, g: 221, b: 212)      // Beige #E8DDD4
    let green = ANSI.rgb(r: 74, g: 222, b: 128)        // Green #4ADE80
    let dark = ANSI.rgb(r: 25, g: 25, b: 25)           // Dark #191919
    let lightText = ANSI.rgb(r: 102, g: 102, b: 102)   // Gray #666666

    private var terminalWidth: Int { Terminal.shared.width }

    func render(_ document: ContentDocument, viewport: Viewport? = nil) -> String {
        var lines: [String] = []

        for (sectionIndex, section) in document.sections.enumerated() {
            let sectionLines = renderSection(section, index: sectionIndex, total: document.sections.count)
            lines.append(contentsOf: sectionLines)
        }

        if let viewport = viewport {
            let start = viewport.offset
            let end = min(start + viewport.visibleLines, lines.count)
            return lines[start..<end].joined(separator: "\n")
        }

        return lines.joined(separator: "\n")
    }

    func renderSection(_ section: Section, index: Int, total: Int) -> [String] {
        var lines: [String] = []

        // Section header
        if let title = section.title {
            switch section.type {
            case .heading(let level):
                lines.append(renderHeading(title, level: level, sectionIndex: index + 1, total: total))
                lines.append("")
            default:
                break
            }
        }

        // Section content
        for block in section.content {
            let blockLines = renderBlock(block)
            lines.append(contentsOf: blockLines)
        }

        lines.append("")
        return lines
    }

    private func renderHeading(_ text: String, level: Int, sectionIndex: Int, total: Int) -> String {
        let indicator = total > 1 ? " \(lightText)[\(sectionIndex)/\(total)]\(ANSI.reset)" : ""

        switch level {
        case 1:
            let line = String(repeating: "═", count: min(text.count + 4, terminalWidth - 10))
            return """
            \(primary)\(ANSI.bold)  \(text)\(ANSI.reset)\(indicator)
            \(primary)  \(line)\(ANSI.reset)
            """
        case 2:
            return "\(primary)\(ANSI.bold)## \(text)\(ANSI.reset)\(indicator)"
        case 3:
            return "\(ANSI.bold)### \(text)\(ANSI.reset)"
        default:
            return "\(ANSI.bold)\(text)\(ANSI.reset)"
        }
    }

    private func renderBlock(_ block: ContentBlock) -> [String] {
        switch block {
        case .text(let attr):
            return [renderAttributedText(attr)]

        case .table(let table):
            return renderTable(table)

        case .codeBlock(let code, let language):
            return renderCodeBlock(code, language: language)

        case .list(let items):
            return renderList(items)

        case .checklist(let items):
            return renderChecklist(items)

        case .image(let alt, _):
            return ["\(lightText)[Image: \(alt)]\(ANSI.reset)"]

        case .link(let text, let url):
            return ["\(ANSI.underline)\(text)\(ANSI.reset) \(lightText)(\(url))\(ANSI.reset)"]

        case .lineBreak:
            return [String(repeating: "─", count: terminalWidth - 4)]
        }
    }

    private func renderAttributedText(_ attr: AttributedText) -> String {
        var result = attr.text

        for style in attr.styles {
            switch style {
            case .bold:
                result = "\(ANSI.bold)\(result)\(ANSI.reset)"
            case .italic:
                result = "\(ANSI.italic)\(result)\(ANSI.reset)"
            case .strikethrough:
                result = "\(ANSI.strikethrough)\(result)\(ANSI.reset)"
            case .code:
                result = "\(ANSI.bgRgb(r: 40, g: 40, b: 40)) \(result) \(ANSI.reset)"
            case .link(let url):
                result = "\(ANSI.underline)\(result)\(ANSI.reset) \(lightText)(\(url))\(ANSI.reset)"
            case .heading:
                result = "\(ANSI.bold)\(result)\(ANSI.reset)"
            }
        }

        return result
    }

    private func renderTable(_ table: Table) -> [String] {
        var lines: [String] = []

        // Calculate column widths
        var widths = table.headers.map { $0.count }
        for row in table.rows {
            for (i, cell) in row.enumerated() where i < widths.count {
                widths[i] = max(widths[i], cell.count)
            }
        }

        // Top border
        lines.append("┌" + widths.map { String(repeating: "─", count: $0 + 2) }.joined(separator: "┬") + "┐")

        // Header row
        var headerCells: [String] = []
        for (i, header) in table.headers.enumerated() {
            let padded = header.padding(toLength: widths[i], withPad: " ", startingAt: 0)
            headerCells.append(" \(ANSI.bold)\(padded)\(ANSI.reset) ")
        }
        lines.append("│" + headerCells.joined(separator: "│") + "│")

        // Header separator
        lines.append("├" + widths.map { String(repeating: "─", count: $0 + 2) }.joined(separator: "┼") + "┤")

        // Data rows
        for row in table.rows {
            var cells: [String] = []
            for (i, cell) in row.enumerated() {
                let width = i < widths.count ? widths[i] : cell.count
                let padded = cell.padding(toLength: width, withPad: " ", startingAt: 0)
                cells.append(" \(padded) ")
            }
            lines.append("│" + cells.joined(separator: "│") + "│")
        }

        // Bottom border
        lines.append("└" + widths.map { String(repeating: "─", count: $0 + 2) }.joined(separator: "┴") + "┘")

        return lines
    }

    private func renderCodeBlock(_ code: String, language: String?) -> [String] {
        var lines: [String] = []
        let bg = ANSI.bgRgb(r: 30, g: 30, b: 30)
        let codeColor = ANSI.rgb(r: 200, g: 200, b: 200)

        let langLabel = language.map { " \(lightText)\($0)\(ANSI.reset)" } ?? ""
        lines.append("\(bg) \(langLabel)")

        for line in code.split(separator: "\n", omittingEmptySubsequences: false) {
            let paddedLine = String(line).padding(toLength: terminalWidth - 4, withPad: " ", startingAt: 0)
            lines.append("\(bg) \(codeColor)\(paddedLine)\(ANSI.reset)")
        }

        lines.append("\(bg) " + String(repeating: " ", count: terminalWidth - 4) + "\(ANSI.reset)")
        return lines
    }

    private func renderList(_ items: [ListItem]) -> [String] {
        var lines: [String] = []

        for item in items {
            let indent = String(repeating: "  ", count: item.depth)
            let bullet = item.depth == 0 ? "•" : "◦"
            lines.append("\(indent)\(bullet) \(item.content.text)")

            // Render children recursively
            for child in item.children {
                let childLines = renderList([child])
                lines.append(contentsOf: childLines)
            }
        }

        return lines
    }

    private func renderChecklist(_ items: [ChecklistItem]) -> [String] {
        var lines: [String] = []

        for item in items {
            let checkbox: String
            if item.isChecked {
                checkbox = "\(green)☑\(ANSI.reset)"
            } else {
                checkbox = "\(lightText)☐\(ANSI.reset)"
            }

            let textStyle = item.isChecked ? "\(ANSI.strikethrough)\(lightText)" : ""
            let text = "\(textStyle)\(item.content.text)\(ANSI.reset)"

            lines.append("\(checkbox) \(text)")
        }

        return lines
    }

    // MARK: - Status Bar

    func renderStatusBar(
        currentSection: Int,
        totalSections: Int,
        scrollPercent: Int,
        mode: String = "NORMAL"
    ) -> String {
        let left = " \(mode) | Section \(currentSection)/\(totalSections)"
        let right = "\(scrollPercent)% | q:quit ?:help "

        let padding = terminalWidth - left.count - right.count
        let middle = String(repeating: " ", count: max(0, padding))

        return "\(ANSI.inverse)\(left)\(middle)\(right)\(ANSI.reset)"
    }

    // MARK: - Help Screen

    func renderHelp() -> String {
        let helpText = """
        \(primary)\(ANSI.bold)  mac-canvas Keyboard Shortcuts\(ANSI.reset)

        \(ANSI.bold)Navigation\(ANSI.reset)
          j/k or ↓/↑    Scroll down/up
          g/G           Go to top/bottom
          PgUp/PgDn     Page up/down
          Tab           Next section
          Shift+Tab     Previous section

        \(ANSI.bold)Sidebar\(ANSI.reset)
          [             Focus session list
          ]             Exit session list
          ↑/↓           Select session
          Enter         Open selected session

        \(ANSI.bold)List Navigation\(ANSI.reset)
          h/l or ←/→    Previous/next item
          Enter         Expand/collapse

        \(ANSI.bold)Actions\(ANSI.reset)
          c             Copy current section
          C             Copy all as markdown
          s             Save to Apple Notes
          e             Compose in Mail
          o             Open file in editor
          r             Open Messages

        \(ANSI.bold)Search\(ANSI.reset)
          /             Start search
          n/N           Next/previous match
          Esc           Clear/cancel

        \(ANSI.bold)Other\(ANSI.reset)
          ?             Toggle this help
          q             Quit

        \(lightText)Press ? or Esc to close\(ANSI.reset)
        """

        return helpText
    }
}

struct Viewport {
    var offset: Int = 0
    var visibleLines: Int = 24
    var totalLines: Int = 0

    var scrollPercent: Int {
        guard totalLines > visibleLines else { return 100 }
        return Int(Double(offset) / Double(totalLines - visibleLines) * 100)
    }

    mutating func scrollDown(by lines: Int = 1) {
        offset = min(offset + lines, max(0, totalLines - visibleLines))
    }

    mutating func scrollUp(by lines: Int = 1) {
        offset = max(0, offset - lines)
    }

    mutating func goToTop() {
        offset = 0
    }

    mutating func goToBottom() {
        offset = max(0, totalLines - visibleLines)
    }

    mutating func pageDown() {
        scrollDown(by: visibleLines - 2)
    }

    mutating func pageUp() {
        scrollUp(by: visibleLines - 2)
    }
}
