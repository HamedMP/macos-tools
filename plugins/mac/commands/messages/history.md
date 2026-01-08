---
description: Get message history with a specific contact
arguments:
  - name: contact
    description: Contact name or phone number
    required: true
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

Get message history with a contact.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

```bash
mac-messages history "<contact>" --limit 50
```

Present conversation thread showing messages and timestamps.

## Canvas output (default)

Unless `--no-canvas` flag is provided, use the **Write tool** to save to `~/.claude/canvas/messages-history-<timestamp>.md`.

The PostToolUse hook will automatically launch mac-canvas GUI.
