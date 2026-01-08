import Foundation
import AppKit
import WebKit

private struct AssociatedKeys {
    static var tableView = "tableViewKey"
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
        level = .normal
        collectionBehavior = [.fullScreenAuxiliary]
        delegate = self

        if config?.gui.alwaysOnTop == true {
            level = .floating
        }

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

        actionBar.wantsLayer = true
        actionBar.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

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

        let alert = NSAlert()
        alert.messageText = "Copied"
        alert.informativeText = "Content copied to clipboard"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self) { _ in }

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
        self.sidebar = NSOutlineView()

        let sidebarContainer = NSView(frame: sidebarScroll.bounds)
        sidebarContainer.autoresizingMask = [.width, .height]

        let header = NSTextField(labelWithString: "Sessions")
        header.font = .boldSystemFont(ofSize: 12)
        header.textColor = NSColor(red: 0.8, green: 0.47, blue: 0.36, alpha: 1)
        header.frame = NSRect(x: 8, y: sidebarContainer.bounds.height - 24, width: 160, height: 20)
        header.autoresizingMask = [.minYMargin]

        sidebarScroll.frame = NSRect(x: 0, y: 0, width: sidebarContainer.bounds.width, height: sidebarContainer.bounds.height - 28)
        sidebarScroll.autoresizingMask = [.width, .height]

        sidebarContainer.addSubview(header)
        sidebarContainer.addSubview(sidebarScroll)

        objc_setAssociatedObject(self, &AssociatedKeys.tableView, tableView, .OBJC_ASSOCIATION_RETAIN)

        let configuration = WKWebViewConfiguration()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 600, height: contentView!.bounds.height), configuration: configuration)
        webView.autoresizingMask = [.width, .height]

        updateContent("<html><body><p style='color: #666; padding: 20px;'>Waiting for content...</p></body></html>")

        splitView.addSubview(sidebarContainer)
        splitView.addSubview(webView)

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
                if let path = previousPath,
                   let index = self.canvasList.firstIndex(where: { $0.path == path }) {
                    tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
                }
            }
        }
    }

    func selectCanvas(path: String) {
        self.selectedPath = path
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let tableView = objc_getAssociatedObject(self, &AssociatedKeys.tableView) as? NSTableView else {
                return
            }
            guard let index = self.canvasList.firstIndex(where: { $0.path == path }) else {
                return
            }
            tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
            tableView.scrollRowToVisible(index)
        }
    }

    func show() {
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - NSWindowDelegate
extension CanvasPanel: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

// MARK: - NSTableViewDelegate, NSTableViewDataSource
extension CanvasPanel: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return canvasList.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let canvas = canvasList[row]

        let identifier = NSUserInterfaceItemIdentifier("SessionCell")
        var cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView

        if cell == nil {
            cell = NSTableCellView()
            cell?.identifier = identifier

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
