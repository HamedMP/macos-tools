---
description: Search macOS Contacts
arguments:
  - name: query
    description: Name or keyword to search for
    required: false
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Contacts Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Step 1: Get contacts

```bash
mac-contacts
```

Or with search:
```bash
mac-contacts search "<query>"
```

Available commands:
- `mac-contacts` - list contacts
- `mac-contacts search <name>` - search by name

## Step 2: Format output

Present contact info in markdown:
```markdown
# Contacts

## Contact Name
- **Company:** Company name
- **Email:** email@example.com
- **Phone:** +1 234 567 890
```

## Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/contacts-<timestamp>.md`
   - Example: `contacts-2026-01-08-2245.md`
   - Format: `contacts-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI.

DO NOT:
- Call /mac:canvas skill
- Run mac-canvas manually
- Use any launch script
