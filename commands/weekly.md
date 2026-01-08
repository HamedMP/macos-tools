---
description: Generate a weekly overview with insights
allowed-tools: Bash, Read
---

Generate a weekly summary covering the past 7 days and upcoming week.

## Data Collection

Run these commands to gather weekly data:

```bash
# This week's calendar (use idag with date range if supported, otherwise just today)
idag

# Recent emails (higher limit for weekly view)
mac-mail list --limit 50

# Recent messages
mac-messages list --limit 30

# All pending reminders
mac-reminders list
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

### Pending Tasks
[From reminders]

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
