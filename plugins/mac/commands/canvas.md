---
description: Open mac-canvas TUI/GUI viewer for rich output display
allowed-tools: Bash
---

Start the mac-canvas viewer to display rich, interactive content.

## Commands

Start canvas in watch mode (default):
```bash
mac-canvas watch
```

With GUI mode:
```bash
mac-canvas watch --gui
```

Named canvas (for multiple sessions):
```bash
mac-canvas watch --name work
mac-canvas watch --name personal
```

Display a file once:
```bash
mac-canvas show /path/to/file.md
```

Clear canvas:
```bash
mac-canvas clear
```

## Configuration

Set default mode:
```bash
mac-canvas config set mode tui   # or gui
mac-canvas config set theme dark # light, dark, or auto
```

## Writing to Canvas

To send content to canvas, write markdown to the canvas file:
```bash
echo "# My Content" > ~/.claude/canvas/default.md
```

Or for named canvases:
```bash
echo "# Work Notes" > ~/.claude/canvas/work.md
```

## Keyboard Shortcuts (TUI)

- `j/k` or arrows - scroll
- `Tab` - next section
- `h/l` - navigate list items
- `c` - copy section
- `C` - copy all
- `s` - save to Notes
- `e` - compose email
- `o` - open in native app
- `/` - search
- `q` - quit
- `?` - help
