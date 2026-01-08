---
description: Show unread emails
arguments:
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Show unread emails from Apple Mail.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-mail unread --limit 20
```

Present emails showing sender, subject, and date. Highlight urgent items.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/mail-unread-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
