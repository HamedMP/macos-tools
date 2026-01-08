---
description: Search emails by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Search emails in Apple Mail.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-mail search "<query>" --limit 20
```

Present matching emails showing sender, subject, and date.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/mail-search-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
