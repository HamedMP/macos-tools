---
description: Search emails by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Search emails for the given query.

```bash
mac-mail search "<query>" --limit 30
```

Searches in subject, sender name, and email address.

Present results showing sender, subject, date, and read status.

## Canvas Output

If `--canvas` flag is included, format as markdown table and write to `~/.claude/canvas/mail-search.md`, then launch canvas if not running.
