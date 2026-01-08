---
description: Create a new note in Apple Notes
arguments:
  - name: title
    description: Title of the note
    required: true
  - name: body
    description: Content of the note (optional)
    required: false
allowed-tools: Bash
---

Create a new note in Apple Notes.

Arguments:
- `$ARGUMENTS.title` - The note title (required)
- `$ARGUMENTS.body` - The note content (optional)

Run the command:
```bash
mac-notes create "$ARGUMENTS.title" --body "$ARGUMENTS.body"
```

If no body is provided, create the note with just the title:
```bash
mac-notes create "$ARGUMENTS.title"
```

Confirm to the user that the note was created.
