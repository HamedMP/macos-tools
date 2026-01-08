---
description: Control Apple Music / Spotify
arguments:
  - name: action
    description: "Action: play, pause, next, prev, now"
    required: false
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Run `mac-music` to see what's playing or control playback.

Available commands:
- `mac-music` or `mac-music now` - now playing
- `mac-music play` - start playback
- `mac-music pause` - pause
- `mac-music next` - next track
- `mac-music prev` - previous track

## Canvas Output

If the user includes `--canvas` flag (for `now` command):

1. Run `mac-music now` and capture the output
2. Format as markdown:
```markdown
# Now Playing

## Track Title
**Artist:** Artist Name
**Album:** Album Name

[Progress bar or time info if available]
```

3. Write to canvas file:
```bash
mkdir -p ~/.claude/canvas
cat > ~/.claude/canvas/music-now.md << 'EOF'
[formatted now playing output]
EOF
```

4. Launch canvas if not running:
```bash
if ! pgrep -x mac-canvas > /dev/null; then
    ${CLAUDE_PLUGIN_ROOT}/hooks/launch-canvas.sh
fi
```
