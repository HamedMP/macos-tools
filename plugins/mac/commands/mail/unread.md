---
description: Show unread emails
arguments:
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Show unread emails from Apple Mail.

```bash
mac-mail unread --limit 20
```

Present emails showing sender, subject, and date. Highlight any that look urgent based on subject.

## Canvas Output

If `--canvas` flag is included, format as markdown table and write to `~/.claude/canvas/mail-unread.md`, then launch canvas if not running.
