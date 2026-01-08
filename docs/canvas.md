# mac-canvas Guide

A TUI/GUI hybrid viewer for displaying rich, interactive content from macos-tools.

## Overview

mac-canvas provides a persistent, interactive display for Claude Code outputs. Instead of content scrolling away in the terminal, canvas keeps it visible and actionable.

**Features:**
- TUI mode (default) - works in any terminal
- GUI mode - native macOS floating panel
- Interactive navigation and actions
- Copy, save to Notes, compose email
- File watching for live updates

## Installation

mac-canvas is included with macos-tools:

```bash
brew install hamedmp/tap/macos-tools
```

## Quick Start

### Start canvas in watch mode

```bash
mac-canvas watch
```

This watches `~/.claude/canvas/default.md` for changes.

### Write content to canvas

```bash
echo "# Hello Canvas" > ~/.claude/canvas/default.md
```

Or from Claude Code, the briefing command can output directly:

```
/work:briefing --canvas
```

## Modes

### TUI Mode (default)

Rich terminal interface with keyboard navigation:

```bash
mac-canvas watch
```

### GUI Mode

Native macOS floating panel:

```bash
mac-canvas watch --gui
```

Or set as default:

```bash
mac-canvas config set mode gui
```

## Multi-Session Support

Canvas automatically detects your terminal session using parent PID, so multiple Claude Code sessions get separate canvases without configuration.

**How it works:**
```
Terminal 1 (PID 12345)
  └── Claude Code
        └── mac-canvas watch  → ~/.claude/canvas/session-12345.md

Terminal 2 (PID 67890)
  └── Claude Code
        └── mac-canvas watch  → ~/.claude/canvas/session-67890.md
```

**Priority for canvas name:**
1. Explicit `--name` flag
2. `CANVAS_SESSION` environment variable
3. Parent PID (automatic)

### Named Canvases

You can also use explicit names:

```bash
mac-canvas watch --name work
mac-canvas watch --name personal
```

Or set via environment:
```bash
export CANVAS_SESSION=myproject
mac-canvas watch
```

## Keyboard Shortcuts (TUI)

### Navigation

| Key | Action |
|-----|--------|
| `j` / `k` or `↓` / `↑` | Scroll down/up |
| `g` / `G` | Go to top/bottom |
| `Page Up` / `Page Down` | Scroll by page |
| `Tab` | Next section |
| `Shift+Tab` | Previous section |

### List Navigation

| Key | Action |
|-----|--------|
| `h` / `l` or `←` / `→` | Previous/next item |
| `Enter` | Expand/collapse item |
| `o` | Open in native app |

### Actions

| Key | Action |
|-----|--------|
| `c` | Copy current section |
| `C` | Copy all as markdown |
| `s` | Save to Apple Notes |
| `e` | Compose email |
| `r` | Reply (for emails/messages) |

### Search

| Key | Action |
|-----|--------|
| `/` | Start search |
| `n` / `N` | Next/previous match |
| `Esc` | Cancel search |

### Other

| Key | Action |
|-----|--------|
| `?` | Toggle help |
| `q` | Quit |

## Configuration

Configuration is stored in `~/.claude/canvas/config.json`.

### Set mode

```bash
mac-canvas config set mode tui   # or gui
```

### Set theme

```bash
mac-canvas config set theme dark   # dark, light, or auto
```

### View all settings

```bash
mac-canvas config list
```

## Integration with Claude Code

### Canvas Command

Open canvas from Claude Code:

```
/mac:canvas
```

### Briefing with Canvas

Send daily briefing to canvas:

```
/work:briefing --canvas
```

### Any Output to Canvas

From any Claude Code command, you can pipe output to canvas:

```bash
echo "# My Output" > ~/.claude/canvas/default.md
```

## Content Support

Canvas renders these markdown elements with rich formatting:

- **Headings** (h1-h6) with section navigation
- **Tables** with box drawing
- **Checklists** with status indicators
- **Code blocks** with syntax highlighting
- **Lists** (ordered and unordered)
- **Links** (clickable in GUI mode)
- **Blockquotes**

## Tips

### Keep canvas running

Run canvas in the background while working:

```bash
mac-canvas watch &
```

### Multiple displays

Use named canvases for different contexts:
- `work` - daily briefing and emails
- `code` - documentation and notes
- `personal` - messages and reminders

### GUI always on top

The GUI panel stays on top by default. Great for reference while coding.

### Quick copy workflow

1. View content in canvas
2. Press `Tab` to navigate to section
3. Press `c` to copy
4. Paste into your editor/email

## Troubleshooting

### Canvas not updating

Check the canvas file exists and has content:

```bash
cat ~/.claude/canvas/default.md
```

### TUI display issues

Try a different terminal. Canvas works best with:
- iTerm2
- Terminal.app
- Alacritty
- Kitty

### GUI not showing

Ensure you're on macOS 13.0+ and have granted terminal permissions.
