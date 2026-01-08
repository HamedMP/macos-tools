---
description: Show emails with attachments
arguments:
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Show emails that have attachments.

```bash
mac-mail attachments --limit 20
```

Present emails showing sender, subject, date, and attachment indicator.

## Canvas Output

If `--canvas` flag is included, format as markdown table and write to `~/.claude/canvas/mail-attachments.md`, then launch canvas if not running.
