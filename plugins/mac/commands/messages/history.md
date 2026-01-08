---
description: Get message history with a specific contact
arguments:
  - name: contact
    description: Contact phone number, email, or name
    required: true
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Get message history with a specific contact.

```bash
mac-messages history "<contact>" --limit 50
```

Present the conversation in chronological order, clearly showing who sent each message (Me vs contact).

## Canvas Output

If `--canvas` flag is included, format as markdown conversation and write to `~/.claude/canvas/messages-history.md`, then launch canvas if not running.
