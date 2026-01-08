---
description: Search and list Apple Notes
arguments:
  - name: query
    description: Search query
    required: false
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Notes Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Step 1: Get notes

```bash
mac-notes list
```

Or with search:
```bash
mac-notes search "<query>"
```

Available commands:
- `mac-notes` or `mac-notes list` - recent notes
- `mac-notes search <query>` - search notes
- `mac-notes folders` - list folders
- `mac-notes create <title> --body <content>` - create a note
- `mac-notes open <title>` - open note in Apple Notes

## Step 2: Format output

Present notes in markdown:
```markdown
# Notes

## Note Title
Folder: Notes | Modified: Jan 8, 2026

Preview of note content...

---
```

## Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/notes-<timestamp>.md`
   - Example: `notes-2026-01-08-2245.md`
   - Format: `notes-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI.

DO NOT:
- Call /mac:canvas skill
- Run mac-canvas manually
- Use any launch script
