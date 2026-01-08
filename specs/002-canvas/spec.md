# mac-canvas - Functional Specification

## Overview

A TUI/GUI hybrid viewer for displaying rich, interactive content from macos-tools. Provides a native display layer for Claude Code outputs with full interactivity.

## Problem Statement

Claude Code outputs text to the terminal, which has limitations:

1. No persistent display - output scrolls away
2. No interactivity - can't click, select, or act on results
3. No rich formatting - limited to basic ANSI colors
4. No integration - can't easily save, copy, or share outputs

Users need:

1. A persistent, scrollable view of Claude outputs
2. Interactive actions (copy, save, send, open)
3. Rich formatting (tables, checklists, markdown)
4. Both terminal-native (TUI) and Mac-native (GUI) options

## Solution

`mac-canvas` - a dual-mode viewer that:

- **TUI mode (default)**: Rich terminal interface with keyboard navigation
- **GUI mode (optional)**: Native macOS floating panel with WebKit rendering

## Functional Requirements

### Core Features

#### Display Modes

| Mode | Description                        | Use Case                      |
| ---- | ---------------------------------- | ----------------------------- |
| TUI  | Terminal-based with ANSI rendering | Default, works everywhere     |
| GUI  | Native NSPanel with WebKit         | Rich rendering, mouse support |

#### Content Types

| Type        | TUI Rendering             | GUI Rendering          |
| ----------- | ------------------------- | ---------------------- |
| Markdown    | ANSI styled text          | Full HTML/CSS          |
| Tables      | Box drawing characters    | HTML tables            |
| Checklists  | `[ ]` / `[x]` with colors | Interactive checkboxes |
| Code blocks | Syntax highlighting       | Syntax highlighting    |
| Images      | ASCII art / placeholder   | Inline images          |
| Links       | Underlined text           | Clickable links        |

### CLI Interface

```bash
# Start canvas in watch mode
mac-canvas watch [--gui] [--file PATH]

# Display content once
mac-canvas show <file.md> [--gui]

# Configure defaults
mac-canvas config set mode <tui|gui>
mac-canvas config set theme <dark|light|auto>

# Clear canvas
mac-canvas clear
```

### Interactive Actions (TUI)

| Key                    | Action                                    |
| ---------------------- | ----------------------------------------- |
| `j` / `k` or `↓` / `↑` | Scroll down/up                            |
| `g` / `G`              | Go to top/bottom                          |
| `Enter`                | Select/expand item                        |
| `c`                    | Copy current section to clipboard         |
| `C`                    | Copy entire content as markdown           |
| `s`                    | Save to Apple Notes                       |
| `e`                    | Compose email with content                |
| `o`                    | Open selected item (contact, note, email) |
| `/`                    | Search within content                     |
| `n` / `N`              | Next/previous search result               |
| `Tab`                  | Cycle through sections                    |
| `q`                    | Quit canvas                               |
| `?`                    | Show help                                 |

### Interactive Actions (GUI)

- Click to select
- Right-click context menu (copy, save, send)
- Drag to select text
- Scroll with trackpad/mouse
- Resize window (remembers position)
- Standard Cmd+C, Cmd+A shortcuts

### List Navigation

When displaying lists (emails, contacts, notes, messages):

```
┌─────────────────────────────────────────────────┐
│  📧 Unread Emails (3)                    [1/3] │
│  ───────────────────────────────────────────── │
│  ▶ From: John Smith                            │
│    Subject: Q1 Proposal Review                 │
│    Preview: Hey, wanted to follow up on...     │
│    [o]pen  [r]eply  [c]opy  [→] next          │
│  ───────────────────────────────────────────── │
│    From: Sarah Chen                            │
│    Subject: Meeting Tomorrow                   │
│    Preview: Can we reschedule to...            │
│  ───────────────────────────────────────────── │
│    From: GitHub                                │
│    Subject: [macos-tools] New issue #42        │
│    Preview: Bug report: mac-mail crashes...    │
└─────────────────────────────────────────────────┘
```

| Key       | Action                                     |
| --------- | ------------------------------------------ |
| `→` / `l` | Next item in list                          |
| `←` / `h` | Previous item in list                      |
| `Enter`   | Expand/collapse item                       |
| `o`       | Open in native app (Mail, Contacts, Notes) |
| `r`       | Reply (for emails/messages)                |

### Integration with macos-tools

#### File-based Communication

Canvas watches `~/.claude/canvas/`:

```
~/.claude/canvas/
├── current.md      # Active content (watched)
├── history/        # Previous sessions
└── config.json     # User preferences
```

#### Claude Code Plugin Integration

New commands in mac plugin:

| Command             | Description                         |
| ------------------- | ----------------------------------- |
| `/mac:canvas`       | Open canvas (starts if not running) |
| `/mac:canvas:clear` | Clear canvas content                |

Modified behavior with canvas:

- `/mac:mail:unread --canvas` - Display in canvas instead of inline
- `/work:briefing --canvas` - Send briefing to canvas
- Or: Global setting to always use canvas for certain outputs

#### Hook Integration

PostToolUse hook can auto-send outputs to canvas:

```yaml
hooks:
  - event: PostToolUse
    pattern: 'mac-(mail|notes|messages|contacts)'
    action: pipe-to-canvas
```

### Sections & Composition

Canvas can display multiple sections:

```
┌─────────────────────────────────────────────────┐
│  Daily Briefing - Jan 8                         │
│  ═══════════════════════════════════════════════│
│                                                 │
│  ## Schedule                           [Tab 1] │
│  ┌──────────┬────────────────────────────────┐ │
│  │ 10:00 AM │ Team standup                   │ │
│  │  2:00 PM │ Call with Max                  │ │
│  └──────────┴────────────────────────────────┘ │
│                                                 │
│  ## Action Items                       [Tab 2] │
│  ☐ Reply to John about proposal               │
│  ☐ Prepare agenda for Max call                │
│  ☑ Review PR #123                             │
│                                                 │
│  ## Emails                             [Tab 3] │
│  3 unread - Press Tab to focus                 │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Save to Notes

When pressing `s`:

1. Convert current view to Apple Notes HTML format
2. Create note with title from first heading or date
3. Preserve tables, checklists, formatting
4. Show confirmation: "Saved to Notes: Daily Briefing - Jan 8"

### Send as Email

When pressing `e`:

1. Show compose dialog (TUI) or open Mail.app (GUI)
2. Pre-fill body with markdown content
3. TUI mode: `To: [____] Subject: [____]`
4. Confirm and send via `mac-mail send`

## Non-Functional Requirements

### Performance

- Startup time: < 100ms
- Re-render on file change: < 50ms
- Smooth scrolling at 60fps
- Memory: < 50MB typical usage

### Security

- No network access (except via macos-tools commands)
- File watching limited to `~/.claude/canvas/`
- No persistent background process when not in use

### Compatibility

- macOS 13.0+ (Ventura)
- Terminal: iTerm2, Terminal.app, Alacritty, Kitty
- True color support (with fallback to 256 colors)

### Accessibility

- VoiceOver support in GUI mode
- High contrast mode
- Keyboard-only navigation

## Configuration

`~/.claude/canvas/config.json`:

```json
{
  "mode": "tui",
  "theme": "auto",
  "tui": {
    "colorScheme": "dark",
    "scrollSpeed": 3,
    "showLineNumbers": false
  },
  "gui": {
    "windowPosition": { "x": 100, "y": 100 },
    "windowSize": { "width": 600, "height": 800 },
    "opacity": 1.0,
    "alwaysOnTop": false
  },
  "actions": {
    "defaultNoteFolder": "Claude Canvas",
    "confirmBeforeSend": true
  }
}
```

## Implementation Status

### Completed

- [x] Core Canvas CLI (`mac-canvas watch`, `show`, `clear`, `config`)
- [x] TUI mode with ANSI rendering
- [x] GUI mode with WebKit rendering
- [x] Markdown parsing (headings, tables, lists, code blocks)
- [x] File watching with auto-refresh
- [x] Session management (multiple canvas files)
- [x] Auto-select latest session on GUI startup
- [x] Window position persistence
- [x] PostToolUse hook for auto-launching GUI
- [x] Dock icon and Cmd+Tab support
- [x] Window close exits app properly
- [x] Action bar (Copy, Save to Notes, Email, Open)
- [x] App icon
- [x] Normal window behavior (not floating by default)
- [x] Email compose preview with styled UI
- [x] Interactive calendar widget with real macOS Calendar data
  - Day/Week/Month views
  - Color-coded events
  - Click-to-add event dialog
  - WebKit message handlers for interactivity

### Not Started

- [ ] Full TUI keyboard navigation (j/k, g/G, search)
- [ ] VoiceOver support
- [ ] Checklist interactivity
- [ ] Context menus in GUI
- [ ] Calendar navigation (prev/next day/week/month)

## Success Metrics

1. TUI renders correctly in major terminals
2. GUI provides native macOS experience
3. All macos-tools outputs displayable in canvas
4. Interactive actions work reliably
5. File watching has no noticeable lag
