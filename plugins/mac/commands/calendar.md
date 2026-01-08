---
description: Show today's calendar events
arguments:
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Calendar Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Step 1: Get calendar events

```bash
mac-calendar
```

If not found: `brew install hamedmp/tap/macos-tools`

## Step 2: Format and display

Present events in a clean markdown format with:
- Birthdays section (if any)
- Schedule table with times

## Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/calendar-<timestamp>.md`
   - Example: `calendar-2026-01-08-2245.md`
   - Format: `calendar-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI and select the latest session.

DO NOT:
- Use idag (use mac-calendar)
- Call /mac:canvas skill
- Run mac-canvas manually
