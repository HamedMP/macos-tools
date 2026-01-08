---
description: Generate a weekly overview with insights
arguments:
  - name: --no-canvas
    description: Disable auto canvas output
    required: false
allowed-tools: Bash, Read, Write
---

Generate a weekly summary covering the past 7 days and upcoming week.

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Data Collection - PARALLEL EXECUTION

**Run ALL commands IN PARALLEL** (single message, multiple Bash calls):

```bash
mac-calendar week
```
```bash
mac-mail list --limit 50
```
```bash
mac-messages list --limit 30
```

## Output Format

```markdown
## Weekly Overview - Week of [Start Date]

### This Week's Highlights
[Key events, important emails, significant conversations from the past week]

### Upcoming This Week
[Calendar events for the coming days]

### Communication Summary
- **Emails**: [X] received, [Y] unread
- **Messages**: Active conversations with [list of contacts]

### Weekly Action Items
- [ ] [Items that should be addressed this week]

### People You Haven't Connected With
[Contacts you usually interact with but haven't this week - if detectable]

### Week Ahead Preparation
[What to prepare for based on upcoming calendar events]
```

## Notes

- Focus on patterns and insights, not just raw data
- Highlight anything that seems urgent or overdue
- Suggest batch tasks that could be done together

## Canvas Output (Default)

**Canvas output is enabled by default.** Unless `--no-canvas` flag is provided, ALWAYS write to canvas.

After generating the summary:

1. Use the **Write tool** to write to `~/.claude/canvas/weekly-<timestamp>.md`
   - Example: `weekly-2026-01-08-2245.md`
   - Format: `weekly-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI and select the latest session.

DO NOT run mac-canvas manually or call /mac:canvas skill.
