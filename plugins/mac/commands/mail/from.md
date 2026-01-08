---
description: Show emails from a specific sender
arguments:
  - name: sender
    description: Sender name or email
    required: true
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Show emails from a specific sender.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-mail from "<sender>" --limit 20
```

Present matching emails showing subject and date.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/mail-from-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
