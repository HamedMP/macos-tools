---
description: Control Apple Music / Spotify
arguments:
  - name: action
    description: "Action: play, pause, next, prev, now"
    required: false
allowed-tools: Bash
---

# Music Command

Control music playback or see what's playing.

## Commands

```bash
mac-music          # Now playing
mac-music play     # Start playback
mac-music pause    # Pause
mac-music next     # Next track
mac-music prev     # Previous track
```

## Output

For `now` command, show:
- Track title
- Artist
- Album

For control commands (play/pause/next/prev), confirm the action was taken.
