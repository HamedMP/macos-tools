import Foundation

class TUIApp {
    private var filePath: String
    private var document: ContentDocument
    private var viewport: Viewport
    private var renderer: ANSIRenderer
    private var terminal: Terminal
    private var watcher: FileWatcher?

    private var currentSection: Int = 0
    private var currentItem: Int = 0
    private var isRunning: Bool = true
    private var showingHelp: Bool = false
    private var searchMode: Bool = false
    private var searchQuery: String = ""
    private var statusMessage: String?

    // Sidebar state
    private var canvasList: [CanvasFile] = []
    private var selectedCanvasIndex: Int = 0
    private var sidebarFocused: Bool = false
    private let sidebarWidth: Int = 24

    struct CanvasFile {
        let name: String
        let path: String
        let modified: Date
    }

    init(filePath: String) {
        self.filePath = filePath
        self.document = ContentDocument()
        self.viewport = Viewport()
        self.renderer = ANSIRenderer()
        self.terminal = Terminal.shared
    }

    init(document: ContentDocument) {
        self.filePath = ""
        self.document = document
        self.viewport = Viewport()
        self.renderer = ANSIRenderer()
        self.terminal = Terminal.shared
    }

    func run() throws {
        setupSignalHandlers()
        terminal.enableRawMode()

        defer {
            terminal.disableRawMode()
            watcher?.stop()
        }

        // Load canvas list and auto-select latest
        refreshCanvasList()
        if let latest = canvasList.first {
            filePath = latest.path
            selectedCanvasIndex = 0
        }

        // Start watching file if path provided
        if !filePath.isEmpty {
            startWatching(filePath)
        } else {
            render()
        }

        // Main event loop
        while isRunning {
            let key = terminal.readKey()
            handleKey(key)

            // Small delay to prevent CPU spinning
            if key == .none {
                Thread.sleep(forTimeInterval: 0.01)
                // Periodically check for new canvas files
                checkForNewCanvases()
            }
        }
    }

    private func startWatching(_ path: String) {
        watcher?.stop()
        watcher = FileWatcher(path: path)
        do {
            try watcher?.watch { [weak self] content in
                self?.handleContentUpdate(content)
            }
        } catch {
            statusMessage = "Error watching: \(error.localizedDescription)"
        }
    }

    private func refreshCanvasList() {
        let canvasDir = CanvasConfig.canvasDirectory
        let fm = FileManager.default

        guard let files = try? fm.contentsOfDirectory(atPath: canvasDir.path) else {
            canvasList = []
            return
        }

        canvasList = files
            .filter { $0.hasSuffix(".md") }
            .compactMap { filename -> CanvasFile? in
                let path = canvasDir.appendingPathComponent(filename).path
                guard let attrs = try? fm.attributesOfItem(atPath: path),
                      let modified = attrs[.modificationDate] as? Date else {
                    return nil
                }
                let name = String(filename.dropLast(3)) // Remove .md
                return CanvasFile(name: name, path: path, modified: modified)
            }
            .sorted { $0.modified > $1.modified } // Most recent first
    }

    private var lastCanvasCheck: Date = Date()
    private func checkForNewCanvases() {
        // Check every 2 seconds
        guard Date().timeIntervalSince(lastCanvasCheck) > 2 else { return }
        lastCanvasCheck = Date()

        let previousPaths = Set(canvasList.map { $0.path })

        refreshCanvasList()

        let currentPaths = Set(canvasList.map { $0.path })
        let newPaths = currentPaths.subtracting(previousPaths)

        // Only auto-switch when a NEW canvas file appears
        if let newPath = newPaths.first,
           let newCanvas = canvasList.first(where: { $0.path == newPath }) {
            // Only switch if the new canvas is the most recent
            if canvasList.first?.path == newCanvas.path {
                filePath = newCanvas.path
                selectedCanvasIndex = 0
                startWatching(filePath)
                showStatus("Switched to: \(newCanvas.name)")
            }
        }
    }

    private func switchToCanvas(at index: Int) {
        guard index >= 0, index < canvasList.count else { return }
        selectedCanvasIndex = index
        let canvas = canvasList[index]
        filePath = canvas.path
        startWatching(filePath)
        sidebarFocused = false
        showStatus("Opened: \(canvas.name)")
    }

    private func setupSignalHandlers() {
        signal(SIGINT) { _ in
            Terminal.shared.disableRawMode()
            exit(0)
        }

        signal(SIGTERM) { _ in
            Terminal.shared.disableRawMode()
            exit(0)
        }
    }

    private func handleContentUpdate(_ content: String) {
        let parser = MarkdownParser()
        document = parser.parse(content)

        // Reset viewport if content changed significantly
        if document.sections.count != viewport.totalLines {
            currentSection = 0
            currentItem = 0
        }

        render()
    }

    private func handleKey(_ key: KeyCode) {
        // Handle search mode separately
        if searchMode {
            handleSearchKey(key)
            return
        }

        // Handle help screen - only dismiss with specific keys
        if showingHelp {
            switch key {
            case .char("?"), .escape, .char("q"):
                showingHelp = false
                render()
            case .none:
                break  // Don't dismiss on no-key
            default:
                break  // Ignore other keys while help is shown
            }
            return
        }

        switch key {
        case .none:
            break

        // Quit
        case .char("q"):
            isRunning = false

        // Help
        case .char("?"):
            showingHelp = true
            renderHelp()

        // Sidebar toggle
        case .char("["):
            refreshCanvasList()  // Refresh list when focusing
            sidebarFocused = true
            showStatus("Sidebar focused (↑↓ select, Enter open, ] exit)")
            render()

        case .char("]"):
            sidebarFocused = false
            render()

        // Sidebar navigation (when focused)
        case .up where sidebarFocused:
            if selectedCanvasIndex > 0 {
                selectedCanvasIndex -= 1
                render()
            }

        case .down where sidebarFocused:
            if selectedCanvasIndex < canvasList.count - 1 {
                selectedCanvasIndex += 1
                render()
            }

        case .enter where sidebarFocused:
            switchToCanvas(at: selectedCanvasIndex)
            render()

        // Scrolling (content)
        case .char("j"), .down:
            viewport.scrollDown(by: 1)
            render()

        case .char("k"), .up:
            viewport.scrollUp(by: 1)
            render()

        case .char("g"):
            viewport.goToTop()
            render()

        case .char("G"):
            viewport.goToBottom()
            render()

        case .pageDown:
            viewport.pageDown()
            render()

        case .pageUp:
            viewport.pageUp()
            render()

        // Section navigation
        case .tab:
            nextSection()

        case .ctrl("i"):  // Shift+Tab (some terminals)
            previousSection()

        // Item navigation
        case .char("l"), .right:
            nextItem()

        case .char("h"), .left:
            previousItem()

        case .enter:
            toggleExpand()

        // Actions
        case .char("c"):
            copySection()

        case .char("C"):
            copyAll()

        case .char("s"):
            saveToNotes()

        case .char("e"):
            composeEmail()

        case .char("o"):
            openInApp()

        case .char("r"):
            reply()

        // Search
        case .char("/"):
            startSearch()

        case .char("n"):
            nextSearchResult()

        case .char("N"):
            previousSearchResult()

        case .escape:
            clearStatus()

        default:
            break
        }
    }

    // MARK: - Rendering

    private func render() {
        terminal.clear()

        // Render sidebar
        renderSidebar()

        let contentStartCol = sidebarWidth + 2

        if document.isEmpty {
            renderEmpty(startCol: contentStartCol)
            renderStatusBar()
            return
        }

        // Calculate total lines
        let contentWidth = terminal.width - contentStartCol
        let allContent = renderer.render(document)
        let lines = allContent.split(separator: "\n", omittingEmptySubsequences: false)
        viewport.totalLines = lines.count
        viewport.visibleLines = terminal.height - 2  // Reserve for status bar

        // Render content
        let visibleStart = viewport.offset
        let visibleEnd = min(visibleStart + viewport.visibleLines, lines.count)

        for (row, i) in (visibleStart..<visibleEnd).enumerated() {
            terminal.moveCursor(to: row + 1, col: contentStartCol)
            let line = String(lines[i])
            // Truncate line to fit content area
            let truncated = String(line.prefix(contentWidth))
            terminal.write(truncated)
        }

        renderStatusBar()
    }

    private func renderSidebar() {
        let borderColor = sidebarFocused ? ANSI.rgb(r: 204, g: 120, b: 92) : ANSI.rgb(r: 60, g: 60, b: 60)
        let headerColor = ANSI.rgb(r: 204, g: 120, b: 92)

        // Header
        terminal.moveCursor(to: 1, col: 1)
        terminal.write("\(headerColor)Sessions\(ANSI.reset)")

        // Border
        terminal.moveCursor(to: 1, col: sidebarWidth)
        for row in 1...terminal.height - 1 {
            terminal.moveCursor(to: row, col: sidebarWidth)
            terminal.write("\(borderColor)│\(ANSI.reset)")
        }

        // Canvas list
        for (i, canvas) in canvasList.prefix(terminal.height - 3).enumerated() {
            terminal.moveCursor(to: i + 2, col: 1)

            let isSelected = i == selectedCanvasIndex
            let prefix = isSelected ? (sidebarFocused ? "▶ " : "● ") : "  "
            let style = isSelected ? ANSI.bold : ""
            let dimStyle = isSelected ? "" : ANSI.dim

            // Truncate name to fit sidebar
            let maxNameLen = sidebarWidth - 4
            var displayName = canvas.name
            if displayName.count > maxNameLen {
                displayName = String(displayName.prefix(maxNameLen - 1)) + "…"
            }

            terminal.write("\(style)\(dimStyle)\(prefix)\(displayName)\(ANSI.reset)")
        }

        // Hint at bottom
        if canvasList.count > 0 {
            terminal.moveCursor(to: terminal.height - 1, col: 1)
            let hint = sidebarFocused ? "↑↓:select ]:exit" : "[:focus"
            terminal.write("\(ANSI.dim)\(hint)\(ANSI.reset)")
        }
    }

    private func renderStatusBar() {
        terminal.moveCursor(to: terminal.height, col: 1)
        let mode = sidebarFocused ? "SIDEBAR" : (searchMode ? "SEARCH" : "NORMAL")
        let statusBar = renderer.renderStatusBar(
            currentSection: currentSection + 1,
            totalSections: document.sections.count,
            scrollPercent: viewport.scrollPercent,
            mode: mode
        )
        terminal.write(statusBar)

        // Show status message if any
        if let message = statusMessage {
            terminal.moveCursor(to: terminal.height - 1, col: sidebarWidth + 2)
            terminal.write(ANSI.clearLine)
            terminal.write(" \(message)")
        }
    }

    private func renderEmpty(startCol: Int = 1) {
        let centerY = terminal.height / 2
        let contentWidth = terminal.width - startCol
        let message = "Waiting for content..."
        let hint = filePath.isEmpty ? "No canvas selected" : "Write to: \(filePath)"

        terminal.moveCursor(to: centerY - 1, col: startCol + (contentWidth - message.count) / 2)
        terminal.write("\(ANSI.dim)\(message)\(ANSI.reset)")

        let hintTruncated = String(hint.prefix(contentWidth - 4))
        terminal.moveCursor(to: centerY + 1, col: startCol + (contentWidth - hintTruncated.count) / 2)
        terminal.write("\(ANSI.dim)\(hintTruncated)\(ANSI.reset)")
    }

    private func renderHelp() {
        terminal.clear()

        let helpLines = renderer.renderHelp().split(separator: "\n", omittingEmptySubsequences: false)
        let startRow = max(1, (terminal.height - helpLines.count) / 2)
        let startCol = max(1, (terminal.width - 50) / 2)

        for (i, line) in helpLines.enumerated() {
            terminal.moveCursor(to: startRow + i, col: startCol)
            terminal.write(String(line))
        }
    }

    // MARK: - Navigation

    private func nextSection() {
        guard document.sections.count > 0 else { return }
        currentSection = (currentSection + 1) % document.sections.count
        currentItem = 0
        scrollToSection()
        render()
    }

    private func previousSection() {
        guard document.sections.count > 0 else { return }
        currentSection = (currentSection - 1 + document.sections.count) % document.sections.count
        currentItem = 0
        scrollToSection()
        render()
    }

    private func scrollToSection() {
        // Calculate approximate line offset for section
        var lineOffset = 0
        for i in 0..<currentSection {
            lineOffset += estimateSectionHeight(document.sections[i])
        }
        viewport.offset = max(0, lineOffset - 2)
    }

    private func estimateSectionHeight(_ section: Section) -> Int {
        var height = 2  // Title + spacing
        for block in section.content {
            switch block {
            case .table(let table):
                height += table.rows.count + 4
            case .list(let items):
                height += items.count
            case .checklist(let items):
                height += items.count
            case .codeBlock(let code, _):
                height += code.split(separator: "\n").count + 2
            default:
                height += 1
            }
        }
        return height
    }

    private func nextItem() {
        guard currentSection < document.sections.count else { return }
        let section = document.sections[currentSection]
        let itemCount = getItemCount(in: section)
        if itemCount > 0 {
            currentItem = (currentItem + 1) % itemCount
            showStatus("Item \(currentItem + 1)/\(itemCount)")
        }
    }

    private func previousItem() {
        guard currentSection < document.sections.count else { return }
        let section = document.sections[currentSection]
        let itemCount = getItemCount(in: section)
        if itemCount > 0 {
            currentItem = (currentItem - 1 + itemCount) % itemCount
            showStatus("Item \(currentItem + 1)/\(itemCount)")
        }
    }

    private func getItemCount(in section: Section) -> Int {
        for block in section.content {
            switch block {
            case .list(let items): return items.count
            case .checklist(let items): return items.count
            case .table(let table): return table.rows.count
            default: continue
            }
        }
        return 0
    }

    private func toggleExpand() {
        guard currentSection < document.sections.count else { return }
        document.sections[currentSection].isExpanded.toggle()
        render()
    }

    // MARK: - Search

    private func handleSearchKey(_ key: KeyCode) {
        switch key {
        case .escape:
            searchMode = false
            searchQuery = ""
            render()

        case .enter:
            searchMode = false
            performSearch()

        case .backspace:
            if !searchQuery.isEmpty {
                searchQuery.removeLast()
            }
            render()
            renderSearchPrompt()

        case .char(let c):
            searchQuery.append(c)
            render()
            renderSearchPrompt()

        default:
            break
        }
    }

    private func startSearch() {
        searchMode = true
        searchQuery = ""
        renderSearchPrompt()
    }

    private func renderSearchPrompt() {
        terminal.moveCursor(to: terminal.height - 1, col: 1)
        terminal.write(ANSI.clearLine)
        terminal.write(" /\(searchQuery)█")
    }

    private func performSearch() {
        // Simple search - just highlight matches in render
        showStatus("Found matches for: \(searchQuery)")
    }

    private func nextSearchResult() {
        showStatus("Next match")
    }

    private func previousSearchResult() {
        showStatus("Previous match")
    }

    // MARK: - Actions

    private func copySection() {
        guard currentSection < document.sections.count else { return }
        let section = document.sections[currentSection]
        let content = sectionToMarkdown(section)
        copyToClipboard(content)
        showStatus("Copied section to clipboard")
    }

    private func copyAll() {
        copyToClipboard(document.rawMarkdown)
        showStatus("Copied all content to clipboard")
    }

    private func copyToClipboard(_ text: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pbcopy")

        let pipe = Pipe()
        task.standardInput = pipe

        do {
            try task.run()
            pipe.fileHandleForWriting.write(text.data(using: .utf8)!)
            pipe.fileHandleForWriting.closeFile()
            task.waitUntilExit()
        } catch {
            showStatus("Failed to copy: \(error.localizedDescription)")
        }
    }

    private func sectionToMarkdown(_ section: Section) -> String {
        var md = ""
        if let title = section.title {
            if case .heading(let level) = section.type {
                md += String(repeating: "#", count: level) + " " + title + "\n\n"
            }
        }

        for block in section.content {
            switch block {
            case .text(let attr):
                md += attr.text + "\n"
            case .checklist(let items):
                for item in items {
                    let checkbox = item.isChecked ? "[x]" : "[ ]"
                    md += "- \(checkbox) \(item.content.text)\n"
                }
            case .list(let items):
                for item in items {
                    md += "- \(item.content.text)\n"
                }
            default:
                break
            }
        }

        return md
    }

    private func saveToNotes() {
        showStatus("Saving to Notes...")

        // Get title - ensure it's not empty and sanitize it
        var title = document.title ?? ""
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            title = "Canvas - \(formatter.string(from: Date()))"
        }
        // Remove any newlines from title
        title = title.components(separatedBy: .newlines).first ?? title

        let content = document.rawMarkdown.isEmpty ? "Empty canvas" : document.rawMarkdown

        // Find mac-notes in PATH or common locations
        let possiblePaths = [
            "/opt/homebrew/bin/mac-notes",
            "/usr/local/bin/mac-notes",
            "/usr/bin/mac-notes"
        ]

        var macNotesPath: String?
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                macNotesPath = path
                break
            }
        }

        guard let notesPath = macNotesPath else {
            showStatus("mac-notes not found. Install with: brew install hamedmp/tap/macos-tools")
            return
        }

        // Write content to temp file
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("canvas-note-\(UUID().uuidString).md")
        do {
            try content.write(to: tempFile, atomically: true, encoding: .utf8)
        } catch {
            showStatus("Failed to create temp file: \(error.localizedDescription)")
            return
        }

        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }

        // Use shell to properly handle the content
        let shellCommand = """
        '\(notesPath)' create '\(title.replacingOccurrences(of: "'", with: "'\\''"))' --body "$(cat '\(tempFile.path)')"
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", shellCommand]

        // Capture stderr for debugging
        let stderrPipe = Pipe()
        let stdoutPipe = Pipe()
        task.standardError = stderrPipe
        task.standardOutput = stdoutPipe

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                showStatus("Saved to Notes: \(title)")
            } else {
                // Read stderr for error details
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrStr = String(data: stderrData, encoding: .utf8) ?? "unknown error"

                // Log to file for debugging
                let logPath = "/tmp/canvas-notes-error.log"
                let logContent = """
                === \(Date()) ===
                Exit code: \(task.terminationStatus)
                Title: \(title)
                Shell command: \(shellCommand)
                Temp file: \(tempFile.path)
                Stderr: \(stderrStr)

                """
                try? logContent.write(toFile: logPath, atomically: true, encoding: .utf8)

                showStatus("Failed (exit:\(task.terminationStatus)) - see /tmp/canvas-notes-error.log")
            }
        } catch {
            showStatus("Error: \(error.localizedDescription)")
        }
    }

    private func composeEmail() {
        showStatus("Opening Mail compose...")

        let subject = document.title ?? "Canvas Export"
        let body = document.rawMarkdown

        // Use AppleScript to open Mail compose
        let script = """
        tell application "Mail"
            activate
            set newMessage to make new outgoing message with properties {subject:"\(subject.replacingOccurrences(of: "\"", with: "\\\""))", visible:true}
            tell newMessage
                set content to "\(body.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))"
            end tell
        end tell
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                showStatus("Mail compose opened")
            } else {
                showStatus("Failed to open Mail")
            }
        } catch {
            showStatus("Error: \(error.localizedDescription)")
        }
    }

    private func openInApp() {
        guard !filePath.isEmpty else {
            showStatus("No file to open")
            return
        }

        showStatus("Opening file...")

        // Open the file with the default application
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = [filePath]

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                showStatus("Opened: \(URL(fileURLWithPath: filePath).lastPathComponent)")
            } else {
                showStatus("Failed to open file")
            }
        } catch {
            showStatus("Error: \(error.localizedDescription)")
        }
    }

    private func reply() {
        showStatus("Opening Messages...")

        // Open Messages app
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "Messages"]

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                showStatus("Messages opened")
            } else {
                showStatus("Failed to open Messages")
            }
        } catch {
            showStatus("Error: \(error.localizedDescription)")
        }
    }

    // MARK: - Status

    private func showStatus(_ message: String) {
        statusMessage = message
        render()

        // Clear status after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.clearStatus()
        }
    }

    private func clearStatus() {
        statusMessage = nil
        render()
    }
}
