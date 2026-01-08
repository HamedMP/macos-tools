---
description: Show emails with attachments
arguments:
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Show emails that have attachments.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-mail attachments --limit 20
```

Present emails showing sender, subject, and attachment info.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/mail-attachments-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
