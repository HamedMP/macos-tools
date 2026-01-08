---
description: Search iMessages by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Search iMessages for a keyword.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-messages search "<query>" --limit 20
```

Present matching messages showing contact, message, and time.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/messages-search-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
