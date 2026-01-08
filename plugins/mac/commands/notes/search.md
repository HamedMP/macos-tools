---
description: Search Apple Notes by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Search Apple Notes for the given query.

```bash
mac-notes search "<query>" --limit 20
```

Present results showing note title, folder, and snippet.

## Canvas Output

If `--canvas` flag is included, format as markdown and write to `~/.claude/canvas/notes-search.md`, then launch canvas if not running.
