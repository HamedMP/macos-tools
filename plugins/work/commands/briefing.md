---
description: Generate an AI summary of your day with action items
arguments:
  - name: query
    description: Optional focus topic (e.g., "receipts", "project alpha")
    required: false
allowed-tools: Bash, Read
---

Generate an AI-powered daily briefing with summary and action items.

## Behavior

### Default (no query)
Gather recent/unread data from all sources:
- Unread emails (since yesterday)
- Today's and tomorrow's calendar events
- Recent messages (last 24 hours)

### With Query (e.g., `/work:briefing receipts`)
Search ALL sources for the topic, regardless of date:
- `mac-mail search "<query>" --limit 20`
- `mac-messages search "<query>" --limit 20`
- `mac-notes search "<query>" --limit 10`
- Calendar events (filter by query in output)

## Data Collection

1. Read config from `~/.claude/mac-config.json` (use defaults if not exists)

2. Run commands based on mode:

**Default mode:**
```bash
idag                           # Today's calendar
mac-mail unread --limit 15     # Unread emails
mac-messages list --limit 10   # Recent messages
```

**Query mode** (e.g., query = "receipts"):
```bash
idag                                    # Calendar (filter in summary)
mac-mail search "receipts" --limit 20   # Search emails
mac-messages search "receipts" --limit 15  # Search messages
mac-notes search "receipts" --limit 10  # Search notes
```

## Output Format

After gathering the data, generate a structured briefing:

```markdown
## Daily Briefing - [Date]

### Executive Summary
[2-3 sentence overview of the day: meetings, urgent emails, key deadlines]

### Today's Schedule
[List of calendar events with times]

### Action Items
- [ ] [Extracted from emails and calendar - things that need doing]
- [ ] [Reply to X about Y]
- [ ] [Prepare for meeting Z]

### Key Deadlines
- [Project/task]: [Due date]

### People to Follow Up With
- [Name]: [Context - what you're waiting on or need to discuss]

### Suggested Priorities
1. [Most important thing based on deadlines and urgency]
2. [Second priority]
3. [Third priority]
```

## Notes

- Extract action items from email subjects and calendar event titles
- Identify deadlines from dates mentioned in emails
- Suggest priorities based on urgency (today's deadlines first)
- If query provided, focus the summary on that topic

## Save to Notes

After presenting the briefing, ask the user if they want to save it to Apple Notes:

"Would you like me to save this briefing to Apple Notes?"

If yes, create the note:
```bash
mac-notes create "Daily Briefing - [Date]" --body "[briefing content]"
```

This allows the user to reference the briefing later on their phone or other devices.
