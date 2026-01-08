---
description: Search iMessages by keyword
arguments:
  - name: query
    description: Search query
    required: true
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Search iMessages for the given query.

```bash
mac-messages search "<query>" --limit 30
```

Options:
- `--sort date|sender` - sort results

Present results showing date, sender, and message text.

## Canvas Output

If `--canvas` flag is included, format as markdown table and write to `~/.claude/canvas/messages-search.md`, then launch canvas if not running.
