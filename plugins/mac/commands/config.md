---
description: Configure which sources to include in productivity commands
allowed-tools: Bash, Read, Write, AskUserQuestion
---

This command configures which data sources to include in /mac:daily and /mac:briefing.

## Configuration Flow

1. Check if config exists at `~/.claude/mac-config.json`

2. If exists, show current configuration and ask if user wants to change it.

3. Use AskUserQuestion to let user select sources:
   - Calendar (today's events via mac-calendar)
   - Mail (unread emails via mac-mail)
   - Messages (recent conversations via mac-messages)
   - Notes (recent notes via mac-notes)

4. Ask for limits:
   - How many emails to include? (default: 10)
   - How many messages to include? (default: 5)
   - How many notes to include? (default: 5)

5. Save configuration to `~/.claude/mac-config.json`:

```json
{
  "sources": ["calendar", "mail", "messages"],
  "limits": {
    "mail": 10,
    "messages": 5,
    "notes": 5
  },
  "createdAt": "2026-01-08T12:00:00Z"
}
```

## Default Configuration

If no config exists and user runs /mac:daily or /mac:briefing, use defaults:
- Sources: calendar, mail, messages
- Mail limit: 10
- Messages limit: 5
- Notes limit: 5
