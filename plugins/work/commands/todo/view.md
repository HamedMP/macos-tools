---
description: View todo items from Apple Notes
allowed-tools: Bash
---

Search Apple Notes for todo lists and checklist items.

## Steps

1. Search notes for common todo patterns:

```bash
mac-notes search "todo" --limit 10
mac-notes search "checklist" --limit 10
mac-notes search "tasks" --limit 10
```

2. Present found todos in a clean format:

```markdown
## Your Todos

### From Notes
[Todo items found in notes - look for checkbox patterns, bullet lists, "TODO:" markers]
```

## Notes

- Apple Notes stores checklists in a special format - the search will find notes containing checklists
- For detailed checklist content, we'd need to export and parse the note
