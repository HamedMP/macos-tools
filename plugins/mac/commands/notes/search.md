---
description: Search Apple Notes by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Search Apple Notes for a keyword.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-notes search "<query>" --limit 20
```

Present matching notes showing title, folder, and preview.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/notes-search-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
