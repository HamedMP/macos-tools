import Foundation
import AppKit
import WebKit

class GUIApp: NSObject {
    private var filePath: String?
    private var document: ContentDocument?
    private var watcher: FileWatcher?
    private var panel: CanvasPanel?
    private var canvasList: [CanvasFile] = []
    private var pollTimer: Timer?

    struct CanvasFile {
        let name: String
        let path: String
        let modified: Date
    }

    init(filePath: String?) {
        self.filePath = filePath
        super.init()
    }

    init(document: ContentDocument) {
        self.document = document
        super.init()
    }

    private func setAppIcon() {
        // Try to load icon from various locations
        let iconPaths = [
            "/usr/local/share/mac-canvas/icon.png",
            "/opt/homebrew/share/mac-canvas/icon.png",
            Bundle.main.path(forResource: "icon", ofType: "png"),
        ].compactMap { $0 }

        for path in iconPaths {
            if let image = NSImage(contentsOfFile: path) {
                NSApp.applicationIconImage = image
                return
            }
        }
    }

    func run() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)  // Normal app with dock icon and Cmd+Tab

        // Set app icon
        setAppIcon()

        // Refresh canvas list
        refreshCanvasList()

        // Create panel with canvas list
        panel = CanvasPanel(canvasList: canvasList, onSelect: { [weak self] path in
            self?.switchToCanvas(path: path)
        })

        // Show panel first so UI is ready
        panel?.show()

        // Load initial content or start watching
        if let path = filePath {
            startWatching(path)
        } else if let doc = document {
            panel?.updateContent(renderToHTML(doc))
        } else if let latest = canvasList.first {
            // Auto-select the most recently modified canvas on startup
            switchToCanvas(path: latest.path)
        }

        // Start polling for new canvases
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForNewCanvases()
        }

        // Run the app
        app.run()
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

    private func checkForNewCanvases() {
        let previousPaths = Set(canvasList.map { $0.path })

        refreshCanvasList()

        let currentPaths = Set(canvasList.map { $0.path })
        let newPaths = currentPaths.subtracting(previousPaths)

        // Only update panel if list changed
        if previousPaths != currentPaths {
            panel?.updateCanvasList(canvasList)
        }

        // Only auto-switch when a NEW canvas file appears
        if let newPath = newPaths.first,
           let newCanvas = canvasList.first(where: { $0.path == newPath }) {
            // Only switch if the new canvas is the most recent
            if canvasList.first?.path == newCanvas.path {
                switchToCanvas(path: newCanvas.path)
            }
        }
    }

    private func switchToCanvas(path: String) {
        filePath = path
        startWatching(path)
        panel?.selectCanvas(path: path)
    }

    private func startWatching(_ path: String) {
        watcher?.stop()
        watcher = FileWatcher(path: path)
        do {
            try watcher?.watch { [weak self] content in
                self?.updateContent(content)
            }
        } catch {
            print("Failed to watch file: \(error)")
        }
    }

    private func updateContent(_ markdown: String) {
        let parser = MarkdownParser()
        let doc = parser.parse(markdown)
        panel?.updateContent(renderToHTML(doc), markdown: markdown)
    }

    private func renderToHTML(_ document: ContentDocument) -> String {
        let renderer = HTMLRenderer()
        return renderer.render(document)
    }
}

class CanvasPanel: NSWindow {
    private var webView: WKWebView!
    private var sidebar: NSOutlineView!
    private var splitView: NSSplitView!
    private var actionBar: NSView!
    private var config: CanvasConfig?
    private var canvasList: [GUIApp.CanvasFile] = []
    private var onSelect: ((String) -> Void)?
    private var selectedPath: String?
    private var currentMarkdown: String = ""

    init(canvasList: [GUIApp.CanvasFile], onSelect: @escaping (String) -> Void) {
        self.canvasList = canvasList
        self.onSelect = onSelect

        // Load config for window position
        config = try? CanvasConfig.load()

        let frame = NSRect(
            x: config?.gui.windowX ?? 100,
            y: config?.gui.windowY ?? 100,
            width: config?.gui.windowWidth ?? 800,
            height: config?.gui.windowHeight ?? 600
        )

        super.init(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        setupPanel()
        setupActionBar()
        setupSplitView()
    }

    private func setupPanel() {
        title = "mac-canvas"
        level = .normal  // Normal window level
        collectionBehavior = [.fullScreenAuxiliary]
        delegate = self  // Handle window close

        // Only float if explicitly configured
        if config?.gui.alwaysOnTop == true {
            level = .floating
        }

        // Save position on move/resize
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidMove),
            name: NSWindow.didMoveNotification,
            object: self
        )
    }

    @objc func windowDidMove(_ notification: Notification) {
        saveWindowPosition()
    }

    private func saveWindowPosition() {
        guard var config = config else { return }
        config.gui.windowX = Int(frame.origin.x)
        config.gui.windowY = Int(frame.origin.y)
        config.gui.windowWidth = Int(frame.width)
        config.gui.windowHeight = Int(frame.height)
        try? config.save()
    }

    private func setupActionBar() {
        let toolbarHeight: CGFloat = 36

        actionBar = NSView(frame: NSRect(
            x: 0,
            y: contentView!.bounds.height - toolbarHeight,
            width: contentView!.bounds.width,
            height: toolbarHeight
        ))
        actionBar.autoresizingMask = [.width, .minYMargin]

        // Toolbar background
        actionBar.wantsLayer = true
        actionBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        // Create buttons
        let buttonSpecs: [(String, String, Selector)] = [
            ("doc.on.doc", "Copy", #selector(copyContent)),
            ("square.and.arrow.down", "Save to Notes", #selector(saveToNotes)),
            ("envelope", "Email", #selector(composeEmail)),
            ("arrow.up.forward.app", "Open", #selector(openInApp))
        ]

        var xOffset: CGFloat = 8
        for (icon, tooltip, action) in buttonSpecs {
            let button = NSButton(frame: NSRect(x: xOffset, y: 4, width: 28, height: 28))
            button.bezelStyle = .texturedRounded
            button.image = NSImage(systemSymbolName: icon, accessibilityDescription: tooltip)
            button.toolTip = tooltip
            button.target = self
            button.action = action
            button.isBordered = true
            actionBar.addSubview(button)
            xOffset += 36
        }

        // Separator
        let separator = NSBox(frame: NSRect(x: 0, y: 0, width: contentView!.bounds.width, height: 1))
        separator.boxType = .separator
        separator.autoresizingMask = [.width]
        actionBar.addSubview(separator)

        contentView?.addSubview(actionBar)
    }

    @objc private func copyContent() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentMarkdown, forType: .string)

        // Show brief notification
        let alert = NSAlert()
        alert.messageText = "Copied"
        alert.informativeText = "Content copied to clipboard"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self) { _ in }

        // Auto-dismiss after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sheets.first?.close()
        }
    }

    @objc private func saveToNotes() {
        let possiblePaths = [
            "/opt/homebrew/bin/mac-notes",
            "/usr/local/bin/mac-notes"
        ]

        var macNotesPath: String?
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                macNotesPath = path
                break
            }
        }

        guard let notesPath = macNotesPath else {
            let alert = NSAlert()
            alert.messageText = "mac-notes not found"
            alert.informativeText = "Install with: brew install hamedmp/tap/macos-tools"
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        let title = "Canvas - \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short))"
        let content = currentMarkdown.isEmpty ? "Empty canvas" : currentMarkdown

        let task = Process()
        task.executableURL = URL(fileURLWithPath: notesPath)
        task.arguments = ["create", title, "--body", content]

        do {
            try task.run()
            task.waitUntilExit()

            let alert = NSAlert()
            if task.terminationStatus == 0 {
                alert.messageText = "Saved to Notes"
                alert.informativeText = title
                alert.alertStyle = .informational
            } else {
                alert.messageText = "Failed to save"
                alert.informativeText = "mac-notes returned error"
                alert.alertStyle = .warning
            }
            alert.runModal()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    @objc private func composeEmail() {
        let subject = "Canvas Export"
        let body = currentMarkdown.replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")

        let script = """
        tell application "Mail"
            activate
            set newMessage to make new outgoing message with properties {subject:"\(subject)", visible:true}
            tell newMessage
                set content to "\(body)"
            end tell
        end tell
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]

        do {
            try task.run()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    @objc private func openInApp() {
        guard let path = selectedPath, !path.isEmpty else {
            let alert = NSAlert()
            alert.messageText = "No file selected"
            alert.informativeText = "Select a canvas session first"
            alert.alertStyle = .informational
            alert.runModal()
            return
        }

        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    private func setupSplitView() {
        let toolbarHeight: CGFloat = 36

        // Create split view below toolbar
        let splitFrame = NSRect(
            x: 0,
            y: 0,
            width: contentView!.bounds.width,
            height: contentView!.bounds.height - toolbarHeight
        )
        splitView = NSSplitView(frame: splitFrame)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autoresizingMask = [.width, .height]

        // Create sidebar
        let sidebarScroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 180, height: contentView!.bounds.height))
        sidebarScroll.hasVerticalScroller = true
        sidebarScroll.autoresizingMask = [.height]

        let tableView = NSTableView(frame: sidebarScroll.bounds)
        tableView.headerView = nil
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.doubleAction = #selector(tableDoubleClicked)
        tableView.target = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("session"))
        column.title = "Sessions"
        column.width = 170
        tableView.addTableColumn(column)

        sidebarScroll.documentView = tableView
        self.sidebar = NSOutlineView() // Keep reference for updates

        // Create header view for sidebar
        let sidebarContainer = NSView(frame: sidebarScroll.bounds)
        sidebarContainer.autoresizingMask = [.width, .height]

        let header = NSTextField(labelWithString: "Sessions")
        header.font = .boldSystemFont(ofSize: 12)
        header.textColor = NSColor(red: 0.8, green: 0.47, blue: 0.36, alpha: 1) // Terracotta
        header.frame = NSRect(x: 8, y: sidebarContainer.bounds.height - 24, width: 160, height: 20)
        header.autoresizingMask = [.minYMargin]

        sidebarScroll.frame = NSRect(x: 0, y: 0, width: sidebarContainer.bounds.width, height: sidebarContainer.bounds.height - 28)
        sidebarScroll.autoresizingMask = [.width, .height]

        sidebarContainer.addSubview(header)
        sidebarContainer.addSubview(sidebarScroll)

        // Store tableView reference
        objc_setAssociatedObject(self, &AssociatedKeys.tableView, tableView, .OBJC_ASSOCIATION_RETAIN)

        // Create webview
        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: contentView!.bounds.height), configuration: configuration)
        webView.autoresizingMask = [.width, .height]

        // Load initial empty state
        updateContent("<html><body><p style='color: #666; padding: 20px;'>Waiting for content...</p></body></html>")

        // Add to split view
        splitView.addSubview(sidebarContainer)
        splitView.addSubview(webView)

        // Set position
        splitView.setPosition(180, ofDividerAt: 0)

        contentView?.addSubview(splitView)
    }

    @objc private func tableDoubleClicked(_ sender: AnyObject) {
        guard let tableView = objc_getAssociatedObject(self, &AssociatedKeys.tableView) as? NSTableView else { return }
        let row = tableView.clickedRow
        if row >= 0 && row < canvasList.count {
            let canvas = canvasList[row]
            onSelect?(canvas.path)
        }
    }

    private var lastRenderedMarkdown: String = ""

    func updateContent(_ html: String, markdown: String = "") {
        // Only reload if content actually changed
        guard markdown != lastRenderedMarkdown else { return }

        self.currentMarkdown = markdown
        self.lastRenderedMarkdown = markdown

        DispatchQueue.main.async {
            self.webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func updateCanvasList(_ list: [GUIApp.CanvasFile]) {
        let previousPath = self.selectedPath
        self.canvasList = list
        DispatchQueue.main.async {
            if let tableView = objc_getAssociatedObject(self, &AssociatedKeys.tableView) as? NSTableView {
                tableView.reloadData()
                // Restore selection after reload
                if let path = previousPath,
                   let index = self.canvasList.firstIndex(where: { $0.path == path }) {
                    tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                }
            }
        }
    }

    func selectCanvas(path: String) {
        self.selectedPath = path
        // Small delay to ensure table view is ready after window is shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let tableView = objc_getAssociatedObject(self, &AssociatedKeys.tableView) as? NSTableView else {
                print("[DEBUG] selectCanvas: tableView not found")
                return
            }
            guard let index = self.canvasList.firstIndex(where: { $0.path == path }) else {
                print("[DEBUG] selectCanvas: path not in list: \(path)")
                print("[DEBUG] canvasList: \(self.canvasList.map { $0.path })")
                return
            }
            print("[DEBUG] selectCanvas: selecting index \(index) for \(path)")
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            tableView.scrollRowToVisible(index)
        }
    }

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct AssociatedKeys {
    static var tableView = "tableViewKey"
}

// MARK: - NSWindowDelegate
extension CanvasPanel: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Terminate app when window is closed
        NSApp.terminate(nil)
    }
}

extension CanvasPanel: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return canvasList.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let canvas = canvasList[row]

        // Create or reuse cell view
        let identifier = NSUserInterfaceItemIdentifier("SessionCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier

            // Create stack view for vertical layout
            let stackView = NSStackView()
            stackView.orientation = .vertical
            stackView.alignment = .leading
            stackView.spacing = 2
            stackView.translatesAutoresizingMaskIntoConstraints = false

            let nameField = NSTextField(labelWithString: "")
            nameField.font = .systemFont(ofSize: 12, weight: .medium)
            nameField.lineBreakMode = .byTruncatingTail
            nameField.tag = 1

            let dateField = NSTextField(labelWithString: "")
            dateField.font = .systemFont(ofSize: 10)
            dateField.textColor = .secondaryLabelColor
            dateField.tag = 2

            stackView.addArrangedSubview(nameField)
            stackView.addArrangedSubview(dateField)

            cell?.addSubview(stackView)

            NSLayoutConstraint.activate([
                stackView.leadingAnchor.constraint(equalTo: cell!.leadingAnchor, constant: 8),
                stackView.trailingAnchor.constraint(equalTo: cell!.trailingAnchor, constant: -8),
                stackView.centerYAnchor.constraint(equalTo: cell!.centerYAnchor)
            ])
        }

        // Update cell content
        if let stackView = cell?.subviews.first as? NSStackView {
            if let nameField = stackView.arrangedSubviews.first(where: { $0.tag == 1 }) as? NSTextField {
                nameField.stringValue = canvas.name
            }
            if let dateField = stackView.arrangedSubviews.first(where: { $0.tag == 2 }) as? NSTextField {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                dateField.stringValue = dateFormatter.string(from: canvas.modified)
            }
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let row = tableView.selectedRow
        if row >= 0 && row < canvasList.count {
            let canvas = canvasList[row]
            selectedPath = canvas.path
            onSelect?(canvas.path)
        }
    }
}

class HTMLRenderer {
    func render(_ document: ContentDocument) -> String {
        var html = ""

        for section in document.sections {
            html += renderSection(section)
        }

        return wrapWithStyles(html)
    }

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

    private func wrapWithStyles(_ body: String) -> String {
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
            </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }
}
