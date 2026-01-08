# mac-canvas - Implementation Plan

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        mac-canvas                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │   Watcher   │───▶│   Parser    │───▶│  Renderer   │    │
│  │  (FSEvents) │    │ (Markdown)  │    │ (TUI/GUI)   │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    │
│                                               │             │
│                                               ▼             │
│                     ┌─────────────────────────────────┐    │
│                     │         Action Handler          │    │
│                     │  (Copy, Save, Send, Navigate)   │    │
│                     └─────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Technology Choices

### TUI Rendering

**Option A: Pure Swift with ANSI**
- Pros: Single binary, fast, consistent with other tools
- Cons: Limited TUI ecosystem in Swift, more work

**Option B: Swift + ncurses**
- Pros: Battle-tested, good terminal support
- Cons: C interop, limited styling

**Option C: Swift wrapper around Bubbletea (via subprocess)**
- Pros: Best TUI framework available
- Cons: Two binaries, Go dependency

**Decision: Option A (Pure Swift with ANSI)**

Rationale:
- Keeps everything in Swift (consistent with macos-tools)
- Single binary for brew formula
- Full control over rendering
- Can achieve good results with modern terminals

### GUI Rendering

**Swift + AppKit + WebKit**
- NSPanel for floating window (no dock icon)
- WKWebView for markdown rendering
- Native feel with web flexibility

### Markdown Parsing

**Swift Markdown (Apple's library)**
- Native Swift, well-maintained
- Produces AST we can render to ANSI or HTML
- Supports CommonMark + extensions

## Module Breakdown

### 1. Core (`Sources/Canvas/Core/`)

```swift
// ContentDocument.swift
struct ContentDocument {
    let sections: [Section]
    let metadata: Metadata
}

struct Section {
    let id: String
    let type: SectionType  // heading, table, list, code, etc.
    let content: MarkdownNode
    var isExpanded: Bool
    var isSelected: Bool
}

// Watcher.swift
class FileWatcher {
    func watch(path: URL, onChange: @escaping (String) -> Void)
    func stop()
}

// Parser.swift
class MarkdownParser {
    func parse(_ markdown: String) -> ContentDocument
}
```

### 2. TUI (`Sources/Canvas/TUI/`)

```swift
// Terminal.swift
class Terminal {
    func enableRawMode()
    func disableRawMode()
    func getSize() -> (width: Int, height: Int)
    func moveCursor(to: Position)
    func write(_ text: String)
    func clear()
}

// ANSIRenderer.swift
class ANSIRenderer {
    func render(_ document: ContentDocument, viewport: Viewport) -> String
    func renderSection(_ section: Section) -> String
    func renderTable(_ table: Table) -> String
    func renderChecklist(_ items: [ChecklistItem]) -> String
}

// TUIApp.swift
class TUIApp {
    var document: ContentDocument
    var viewport: Viewport
    var selectedIndex: Int

    func run()
    func handleKey(_ key: KeyCode)
    func scroll(by: Int)
    func selectNext()
    func copySelection()
}

// KeyHandler.swift
enum KeyCode { case up, down, left, right, enter, tab, char(Character), ... }
func readKey() -> KeyCode
```

### 3. GUI (`Sources/Canvas/GUI/`)

```swift
// CanvasPanel.swift
class CanvasPanel: NSPanel {
    let webView: WKWebView
    func updateContent(_ html: String)
    func show()
    func hide()
}

// HTMLRenderer.swift
class HTMLRenderer {
    func render(_ document: ContentDocument) -> String
    func wrapWithStyles(_ body: String) -> String
}

// GUIApp.swift
class GUIApp: NSObject, NSApplicationDelegate {
    var panel: CanvasPanel
    var watcher: FileWatcher

    func applicationDidFinishLaunching(_ notification: Notification)
}
```

### 4. Actions (`Sources/Canvas/Actions/`)

```swift
// Clipboard.swift
func copyToClipboard(_ text: String)
func copyAsMarkdown(_ document: ContentDocument)

// NotesAction.swift
func saveToNotes(_ document: ContentDocument, folder: String?) async throws -> String

// MailAction.swift
func composeEmail(to: String?, subject: String?, body: String) async throws

// OpenAction.swift
func openInApp(_ item: Item)  // Opens mail, contact, note in native app
```

### 5. CLI (`Sources/Canvas/main.swift`)

```swift
@main
struct CanvasCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "mac-canvas",
        subcommands: [Watch.self, Show.self, Config.self, Clear.self]
    )
}

struct Watch: ParsableCommand {
    @Flag var gui: Bool = false
    @Option var file: String?

    func run() throws { ... }
}
```

## File Structure

```
Sources/Canvas/
├── main.swift
├── Core/
│   ├── ContentDocument.swift
│   ├── FileWatcher.swift
│   ├── MarkdownParser.swift
│   └── Config.swift
├── TUI/
│   ├── Terminal.swift
│   ├── ANSIRenderer.swift
│   ├── TUIApp.swift
│   ├── KeyHandler.swift
│   ├── Viewport.swift
│   └── Styles.swift
├── GUI/
│   ├── CanvasPanel.swift
│   ├── HTMLRenderer.swift
│   ├── GUIApp.swift
│   └── Resources/
│       ├── canvas.css
│       └── canvas.js
└── Actions/
    ├── Clipboard.swift
    ├── NotesAction.swift
    ├── MailAction.swift
    └── OpenAction.swift
```

## Implementation Phases

### Phase 1: Core Foundation
- File watcher with FSEvents
- Markdown parser using Swift Markdown
- Basic content document model
- CLI structure with ArgumentParser

### Phase 2: TUI Renderer
- Terminal raw mode handling
- ANSI escape code renderer
- Basic scrolling and viewport
- Keyboard input handling

### Phase 3: TUI Interactivity
- Section navigation (Tab)
- List item navigation (arrow keys)
- Copy to clipboard
- Search within content

### Phase 4: Actions
- Save to Apple Notes (reuse Notes tool code)
- Compose email (reuse Mail tool code)
- Open in native app

### Phase 5: GUI Mode
- NSPanel setup
- WebKit integration
- HTML/CSS renderer
- Window position memory

### Phase 6: Polish & Integration
- Theme support (dark/light/auto)
- Claude Code plugin commands
- Hook integration
- Error handling and edge cases

## Dependencies

### Swift Packages

```swift
// Package.swift additions
.package(url: "https://github.com/apple/swift-markdown", from: "0.3.0"),
.package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
```

### System Frameworks

- Foundation (file watching, process)
- AppKit (GUI mode)
- WebKit (HTML rendering in GUI)
- CoreServices (FSEvents)

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Terminal compatibility | Test on iTerm2, Terminal.app, Alacritty; provide fallbacks |
| Raw mode issues | Proper cleanup on crash/exit with signal handlers |
| Large files | Virtualized rendering, only render visible viewport |
| FSEvents delays | Debounce with 50ms threshold |

## Testing Strategy

1. **Unit tests**: Parser, renderer output, action handlers
2. **Integration tests**: File watching, clipboard, Notes integration
3. **Manual testing**: Different terminals, GUI on various macOS versions
4. **Snapshot tests**: TUI output comparison
