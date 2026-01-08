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
        app.setActivationPolicy(.regular)

        setAppIcon()
        refreshCanvasList()

        panel = CanvasPanel(canvasList: canvasList, onSelect: { [weak self] path in
            self?.switchToCanvas(path: path)
        })

        panel?.show()

        if let path = filePath {
            startWatching(path)
        } else if let doc = document {
            panel?.updateContent(renderToHTML(doc))
        } else if let latest = canvasList.first {
            switchToCanvas(path: latest.path)
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkForNewCanvases()
        }

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
                let name = String(filename.dropLast(3))
                return CanvasFile(name: name, path: path, modified: modified)
            }
            .sorted { $0.modified > $1.modified }
    }

    private func checkForNewCanvases() {
        let previousPaths = Set(canvasList.map { $0.path })

        refreshCanvasList()

        let currentPaths = Set(canvasList.map { $0.path })
        let newPaths = currentPaths.subtracting(previousPaths)

        if previousPaths != currentPaths {
            panel?.updateCanvasList(canvasList)
        }

        if let newPath = newPaths.first,
           let newCanvas = canvasList.first(where: { $0.path == newPath }) {
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
