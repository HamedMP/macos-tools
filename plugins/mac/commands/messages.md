---
description: List recent iMessage conversations
arguments:
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Messages Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Step 1: Get messages

```bash
mac-messages list --limit 20
```

Available commands:
- `mac-messages` or `mac-messages list` - recent conversations
- `mac-messages search <query>` - search messages
- `mac-messages history <contact>` - messages with a contact
- `mac-messages send <phone> "text"` - send message (requires confirmation)

Options:
- `--limit N` - limit results (default: 20)

## Step 2: Format output

Present conversations in a markdown table:
```markdown
# Messages

| Contact | Last Message | Time |
|---------|--------------|------|
| Name | Message preview... | 2:30 PM |
```

## Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/messages-<timestamp>.md`
   - Example: `messages-2026-01-08-2245.md`
   - Format: `messages-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI.

DO NOT:
- Call /mac:canvas skill
- Run mac-canvas manually
- Use any launch script
