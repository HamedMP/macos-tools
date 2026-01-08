---
description: Add a todo item to Apple Notes or Reminders
arguments:
  - name: text
    description: The todo item text
    required: true
  - name: destination
    description: Where to add - "notes" or "reminders" (default: reminders)
    required: false
allowed-tools: Bash
---

Add a todo item to either Apple Reminders or Apple Notes.

## Arguments

- `text`: The todo item to add (required)
- `destination`: "reminders" (default) or "notes"

## Adding to Reminders (default)

Use AppleScript to add a reminder:

```bash
osascript -e 'tell application "Reminders" to make new reminder with properties {name:"<text>"}'
```

## Adding to Notes

Use AppleScript to append to a "Todo" note:

```bash
osascript -e '
tell application "Notes"
    set todoNote to note "Todo" of folder "Notes"
    set body of todoNote to (body of todoNote) & "<br>- [ ] <text>"
end tell
'
```

If no "Todo" note exists, create one first.

## Output

Confirm the todo was added:

```
Added to Reminders: "<text>"
```

or

```
Added to Notes (Todo): "<text>"
```
