---
description: Show today's overview from configured sources (calendar, mail, messages, notes)
allowed-tools: Bash, Read
---

Show a daily overview combining data from multiple macOS sources.

## Steps

1. Read configuration from `~/.claude/mac-config.json` (use defaults if not exists)

Default config:
```json
{
  "sources": ["calendar", "mail", "messages"],
  "limits": { "mail": 10, "messages": 5, "notes": 5 }
}
```

2. For each configured source, run the appropriate command:

**Calendar** (if enabled):
```bash
idag
```

**Mail** (if enabled):
```bash
mac-mail unread --limit <limit>
```

**Messages** (if enabled):
```bash
mac-messages list --limit <limit>
```

**Notes** (if enabled):
```bash
mac-notes list --limit <limit>
```

3. Present the raw data in organized sections:

```
## Daily Overview - January 8, 2026

### Calendar
[events from idag]

### Unread Emails (10)
[emails from mac-mail unread]

### Recent Messages
[conversations from mac-messages]
```

This command shows RAW DATA. For an AI-generated summary with action items, use /mac:briefing instead.
