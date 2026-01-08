---
description: List recent emails from Apple Mail
arguments:
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Mail Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Step 1: Get emails

```bash
mac-mail list --limit 20
```

Available commands:
- `mac-mail` or `mac-mail list` - recent emails
- `mac-mail search <query>` - search emails
- `mac-mail unread` - unread emails only
- `mac-mail from <sender>` - emails from sender
- `mac-mail attachments` - emails with attachments

Options:
- `--limit N` - limit results (default: 20)

## Step 2: Format output

Present emails in a markdown table:
```markdown
# Mail

| From | Subject | Date |
|------|---------|------|
| sender | subject line | date |
```

## Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/mail-<timestamp>.md`
   - Example: `mail-2026-01-08-2245.md`
   - Format: `mail-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI.

DO NOT:
- Call /mac:canvas skill
- Run mac-canvas manually
- Use any launch script
