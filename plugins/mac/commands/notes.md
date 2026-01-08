---
description: Search and list Apple Notes
arguments:
  - name: query
    description: Search query
    required: false
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Run `mac-notes` to list recent notes.

Available commands:
- `mac-notes` or `mac-notes list` - recent notes
- `mac-notes search <query>` - search notes
- `mac-notes folders` - list folders
- `mac-notes create <title> --body <content>` - create a note

Present the notes in a clean format.

## Canvas Output

If the user includes `--canvas` flag:

1. Run the command and capture the output
2. Format as markdown:
```markdown
# Notes

## Note Title
Folder: Notes | Modified: Jan 8, 2025

Preview of note content...

---
```

3. Write to canvas file:
```bash
mkdir -p ~/.claude/canvas
cat > ~/.claude/canvas/notes-$(date +%Y%m%d-%H%M).md << 'EOF'
[formatted notes output]
EOF
```

4. Launch canvas if not running:
```bash
if ! pgrep -x mac-canvas > /dev/null; then
    ${CLAUDE_PLUGIN_ROOT}/hooks/launch-canvas.sh
fi
```
