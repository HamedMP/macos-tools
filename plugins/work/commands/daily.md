---
description: Show today's overview from configured sources (calendar, mail, messages, notes)
arguments:
  - name: --no-canvas
    description: Disable auto canvas output
    required: false
allowed-tools: Bash, Read, Write
---

Show a daily overview combining data from multiple macOS sources.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Steps

1. Read configuration from `~/.claude/mac-config.json` (use defaults if not exists)

Default config:
```json
{
  "sources": ["calendar", "mail", "messages"],
  "limits": { "mail": 10, "messages": 5, "notes": 5 }
}
```

2. **Run ALL commands IN PARALLEL** (single message, multiple Bash calls):

```bash
mac-calendar
```
```bash
mac-mail unread --limit 10
```
```bash
mac-messages list --limit 5
```

3. Present the raw data in organized sections:

```
## Daily Overview - January 8, 2026

### Calendar
[events from mac-calendar]

### Unread Emails
[emails from mac-mail unread]

### Recent Messages
[conversations from mac-messages]
```

This command shows RAW DATA. For an AI-generated summary with action items, use /work:briefing instead.

## Canvas Output (Default)

**Canvas output is enabled by default.** Unless `--no-canvas` flag is provided, ALWAYS write to canvas.

After gathering data:

1. Use the **Write tool** to write to `~/.claude/canvas/daily-<timestamp>.md`
   - Example: `daily-2026-01-08-2245.md`
   - Format: `daily-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI and select the latest session.

DO NOT run mac-canvas manually or call /mac:canvas skill.
