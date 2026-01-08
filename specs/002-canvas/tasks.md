# mac-canvas - Task Breakdown

## Phase 1: Core Foundation

### 1.1 Project Setup
- [x] Add Canvas target to Package.swift
- [x] Add swift-markdown dependency
- [x] Create directory structure under Sources/Canvas/
- [x] Set up main.swift with ArgumentParser CLI

### 1.2 File Watcher
- [x] Implement FileWatcher using FSEvents
- [x] Add debouncing (50ms) to prevent rapid re-renders
- [x] Create canvas directory structure (~/.claude/canvas/)
- [x] Handle file not existing (create on first write)

### 1.3 Markdown Parser
- [x] Integrate swift-markdown library
- [x] Create ContentDocument model
- [x] Parse headings into sections
- [x] Parse tables into structured data
- [x] Parse checklists (- [ ] and - [x])
- [x] Parse code blocks with language detection
- [x] Handle nested content

### 1.4 Configuration
- [x] Define Config struct
- [x] Load/save config.json
- [x] Implement `mac-canvas config` subcommand
- [x] Support mode, theme, and action settings

---

## Phase 2: TUI Renderer

### 2.1 Terminal Handling
- [x] Implement raw mode enable/disable
- [x] Get terminal size (TIOCGWINSZ)
- [x] Handle SIGWINCH for resize
- [x] Set up cleanup on SIGINT/SIGTERM
- [x] Implement cursor movement

### 2.2 ANSI Renderer
- [x] Define color palette (match Claude Code brand)
- [x] Render headings with colors and borders
- [x] Render paragraphs with word wrapping
- [x] Render tables with box drawing characters
- [x] Render checklists with status colors
- [x] Render code blocks with background
- [x] Render links (underlined)
- [x] Render emphasis (bold, italic)

### 2.3 Viewport & Scrolling
- [x] Implement Viewport struct (offset, visible lines)
- [x] Calculate content height
- [x] Scroll up/down by line
- [x] Scroll up/down by page
- [x] Go to top/bottom
- [x] Show scroll indicator

### 2.4 Main Loop
- [x] Implement TUIApp main loop
- [x] Handle keyboard input
- [x] Re-render on file change
- [x] Re-render on terminal resize
- [x] Clean exit on 'q'

---

## Phase 3: TUI Interactivity

### 3.1 Section Navigation
- [x] Track current section index
- [x] Implement Tab to cycle sections
- [x] Highlight current section
- [x] Auto-scroll to show selected section
- [x] Show section indicator [Tab 1/3]

### 3.2 List Navigation
- [ ] Detect list sections (emails, contacts, notes)
- [ ] Track current item in list
- [ ] Arrow keys to navigate items
- [ ] Expand/collapse items with Enter
- [ ] Show navigation hints [→ next]

### 3.3 Search
- [ ] Implement '/' to enter search mode
- [ ] Text input for search query
- [ ] Highlight matches in content
- [ ] 'n'/'N' to jump between matches
- [ ] Esc to exit search mode
- [ ] Show match count

### 3.4 Help Screen
- [x] Implement '?' to show help
- [x] List all keybindings
- [x] Show current mode/state
- [x] Any key to dismiss

---

## Phase 4: Actions

### 4.1 Clipboard
- [x] Implement copy section ('c')
- [x] Implement copy all ('C')
- [x] Copy as plain text
- [x] Copy as markdown (preserve formatting)
- [x] Show confirmation message

### 4.2 Save to Notes
- [x] Reuse HTML conversion from Notes tool
- [x] Implement 's' action
- [ ] Show folder selection (optional)
- [x] Create note with proper title
- [x] Show confirmation with note name

### 4.3 Compose Email
- [x] Implement 'e' action (opens Mail.app compose)
- [ ] Show TUI compose dialog (stretch goal)
  - [ ] To: field with input
  - [ ] Subject: field with input
  - [ ] Preview body
  - [ ] Confirm/cancel
- [x] Use AppleScript to open Mail compose
- [x] Show confirmation

### 4.4 Open in App
- [x] Implement 'o' action (opens file in default editor)
- [x] Implement 'r' action (opens Messages app)
- [ ] Detect item type and route intelligently (stretch goal)

---

## Phase 5: GUI Mode

### 5.1 NSPanel Setup
- [x] Create CanvasPanel class
- [x] Configure as floating, no dock icon
- [x] Set up window level (above normal)
- [x] Handle window close (hide, don't quit)
- [ ] Remember window position/size

### 5.2 WebKit Integration
- [x] Add WKWebView to panel
- [x] Load base HTML template
- [x] Inject content via JavaScript
- [ ] Handle navigation (open links in browser)

### 5.3 HTML Renderer
- [x] Convert ContentDocument to HTML
- [x] Create CSS stylesheet (dark/light themes)
- [x] Style tables, code blocks, checklists
- [ ] Add interactive checkbox handlers
- [x] Style scrollbars

### 5.4 GUI Actions
- [ ] Right-click context menu
- [ ] Copy selection (Cmd+C)
- [ ] Select all (Cmd+A)
- [ ] Save to Notes menu item
- [ ] Send as Email menu item

### 5.5 GUI App Lifecycle
- [x] Implement GUIApp as NSApplicationDelegate
- [x] Start file watcher
- [x] Update content on file change
- [x] Handle activation/deactivation
- [x] Proper cleanup on quit

---

## Phase 6: Polish & Integration

### 6.1 Themes
- [x] Define dark theme colors
- [ ] Define light theme colors
- [ ] Implement auto theme (follow system)
- [x] Apply theme to TUI renderer
- [x] Apply theme to GUI CSS

### 6.2 Claude Code Plugin
- [x] Add `/mac:canvas` command
- [ ] Add `/mac:canvas:clear` command
- [x] Update other commands with --canvas flag
- [x] Document canvas integration in plugin README

### 6.3 Hook Integration
- [x] Create PostToolUse hook for auto-launch (canvas-autolaunch.md)
- [x] Document hook configuration (in canvas-autolaunch.md)
- [x] Test with briefing output

### 6.4 Error Handling
- [x] Handle missing canvas directory
- [x] Handle malformed markdown
- [ ] Handle terminal not supporting features
- [ ] Graceful degradation for unsupported terminals

### 6.5 Documentation
- [x] Add canvas-specific docs (docs/canvas.md)
- [x] Document all keybindings
- [ ] Update main README with canvas section
- [ ] Add screenshots/GIFs of TUI and GUI

### 6.6 Brew Formula
- [x] Add mac-canvas to formula
- [x] Test installation
- [ ] Update version (pending release)

---

## Phase 7: Multi-Session Support (NEW)

### 7.1 Session Detection
- [x] Use parent PID for automatic session identification
- [x] Support explicit --name flag
- [x] Support CANVAS_SESSION env var
- [x] Priority: explicit > env > parent PID

### 7.2 Sidebar with Session List
- [x] Scan ~/.claude/canvas/ for .md files
- [x] Display sidebar with session list
- [x] Show session name and modified time
- [x] Highlight selected session
- [x] Press '[' to focus sidebar
- [x] Up/down to navigate sessions
- [x] Enter to switch to selected session
- [x] Press ']' to return to content

### 7.3 Auto-Switch to Latest
- [x] Poll for new canvas files every 2 seconds
- [x] Auto-switch to newest when new content arrives
- [x] Don't auto-switch if user manually selected a session

---

## Phase 8: Auto-Launch & Split Pane (NEW)

### 8.1 Claude Code Hook for Auto-Launch
- [x] Create PostToolUse hook that detects canvas writes (canvas-autolaunch.md)
- [x] Auto-launch mac-canvas if not running
- [x] Only trigger when ~/.claude/canvas/*.md is written

### 8.2 Split Pane Support
- [x] Detect terminal type (iTerm2, Warp, Ghostty, Kitty, tmux, Zellij, Terminal.app)
- [x] iTerm2: Use AppleScript to create split pane
- [x] Warp: Use AppleScript with Cmd+D keystroke
- [x] Ghostty: Use AppleScript with Cmd+D keystroke
- [x] Kitty: Use kitty @ launch command
- [x] tmux: Use tmux split-window command
- [x] Zellij: Use zellij run command
- [x] Fallback: Open in new terminal window (Terminal.app)
- [ ] Configuration option to disable split pane

### 8.3 Briefing Integration
- [x] Briefing command outputs to canvas by default
- [x] Briefing uses parallel data collection for speed
- [x] Briefing auto-launches canvas via launch script

---

## Stretch Goals (Post-MVP)

### S1. Advanced TUI Features
- [ ] Syntax highlighting for code blocks
- [ ] Image rendering (ASCII art via libsixel or kitty protocol)
- [ ] Split view (multiple canvases)
- [ ] Tabs for multiple documents

### S2. Advanced GUI Features
- [ ] Resizable sections
- [ ] Drag-and-drop files
- [ ] Print support
- [ ] Export to PDF

### S3. Real-time Collaboration
- [ ] Watch multiple files
- [ ] Diff view for changes
- [ ] History navigation

---

## Progress Summary

| Phase | Completed | Total | Status |
|-------|-----------|-------|--------|
| Phase 1 | 13 | 13 | Done |
| Phase 2 | 16 | 16 | Done |
| Phase 3 | 6 | 15 | In Progress |
| Phase 4 | 11 | 12 | Done |
| Phase 5 | 12 | 16 | In Progress |
| Phase 6 | 11 | 14 | In Progress |
| Phase 7 | 11 | 11 | Done |
| Phase 8 | 12 | 13 | Done |

## Current Focus
- Testing and polish
- Light theme and auto theme support
- GUI right-click context menu

---

## Recent Updates (Jan 8, 2026)

- Added `mac-calendar` to macos-tools package (consolidated from idag)
- Added `--canvas` flag to all plugin commands
- Briefing now outputs to canvas by default
- Briefing uses parallel data collection for faster execution
- Fixed Warp terminal split pane support (Cmd+D instead of Cmd+Shift+D)
- Added multi-terminal support: iTerm2, Warp, Ghostty, Kitty, tmux, Zellij, Terminal.app
