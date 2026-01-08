---
description: Open a note in Apple Notes
arguments:
  - name: title
    description: Note title or partial title to search
    required: true
allowed-tools: Bash
---

Open a note in Apple Notes by title.

```bash
/usr/local/bin/mac-notes open "<title>"
```

If multiple notes match, opens the most recently modified one.

Examples:
- `/mac:notes:open briefing` - Opens the most recent briefing note
- `/mac:notes:open "Daily Briefing"` - Opens a specific note
