---
description: Add a todo item to Apple Notes
arguments:
  - name: text
    description: The todo item text
    required: true
allowed-tools: Bash
---

Add a todo item to Apple Notes.

## Arguments

- `text`: The todo item to add (required)

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
Added to Notes (Todo): "<text>"
```
