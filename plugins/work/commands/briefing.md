---
description: Generate an AI summary of your day with action items
arguments:
  - name: query
    description: Optional focus topic (e.g., "receipts", "project alpha")
    required: false
  - name: --no-canvas
    description: Disable auto canvas output
    required: false
allowed-tools: Bash, Read, Write, Task
---

Generate an AI-powered daily briefing with summary and action items.

**Canvas output is enabled by default** - the briefing will automatically display in mac-canvas. Use `--no-canvas` to disable.

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

## Data Collection - PARALLEL EXECUTION

**IMPORTANT: Run ALL data collection commands IN PARALLEL using multiple Bash tool calls in a single message.** This significantly speeds up the briefing.

1. Read config from `~/.claude/mac-config.json` (use defaults if not exists)

2. Run ALL commands in parallel (single message, multiple Bash calls):

**Default mode - run these 3 commands in PARALLEL:**
```bash
mac-calendar                           # Today's calendar
```
```bash
mac-mail unread --limit 15     # Unread emails
```
```bash
mac-messages list --limit 10   # Recent messages
```

**Query mode** (e.g., query = "receipts") - run these 4 commands in PARALLEL:
```bash
mac-calendar                                    # Calendar (filter in summary)
```
```bash
mac-mail search "receipts" --limit 20   # Search emails
```
```bash
mac-messages search "receipts" --limit 15  # Search messages
```
```bash
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

## Canvas Output (Default)

**Canvas output is enabled by default.** Unless `--no-canvas` flag is provided, ALWAYS write the briefing to canvas.

After generating the briefing content:

1. Use the **Write tool** to write to `~/.claude/canvas/briefing-<timestamp>.md`
   - Example: `briefing-2026-01-08-2245.md`
   - Format: `briefing-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI and select the latest session.

DO NOT run mac-canvas manually or call /mac:canvas skill.

The canvas provides interactive viewing with:
- Auto-switches to latest briefing
- Scrollable sections with Tab navigation
- Copy to clipboard (press `c`)
- Save to Notes (press `s`)
- Navigate action items with arrow keys
- Sidebar showing all sessions (press `[` to focus)
