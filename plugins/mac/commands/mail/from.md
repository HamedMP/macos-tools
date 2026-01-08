---
description: Show emails from a specific sender
arguments:
  - name: sender
    description: Sender email or name
    required: true
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Show emails from a specific sender.

```bash
mac-mail from "<sender>" --limit 20
```

Present emails showing subject, date, and read status.

## Canvas Output

If `--canvas` flag is included, format as markdown table and write to `~/.claude/canvas/mail-from.md`, then launch canvas if not running.
