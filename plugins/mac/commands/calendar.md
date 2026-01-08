---
description: Show today's calendar events
arguments:
  - name: --widget
    description: Show interactive calendar widget (day/week/month views)
    required: false
  - name: --week
    description: Show week view in widget mode
    required: false
  - name: --month
    description: Show month view in widget mode
    required: false
  - name: --no-canvas
    description: Disable canvas output
    required: false
allowed-tools: Bash, Write
---

# Calendar Command

**Canvas output is enabled by default.** Use `--no-canvas` to disable.

## Widget Mode (--widget)

When `--widget` flag is provided, show an interactive calendar with:
- Real events from macOS Calendar
- Day/Week/Month view toggle
- Click on time slots to add events
- Color-coded events with locations

Write to canvas with the appropriate view directive:

```markdown
<!-- calendar:live:day -->   # Default day view
<!-- calendar:live:week -->  # With --week flag
<!-- calendar:live:month --> # With --month flag
```

Example: `~/.claude/canvas/calendar-widget-2026-01-09-1430.md`

## Standard Mode (default)

### Step 1: Get calendar events

```bash
mac-calendar
```

If not found: `brew install hamedmp/tap/macos-tools`

### Step 2: Format and display

Present events in a clean markdown format with:
- Birthdays section (if any)
- Schedule table with times

### Step 3: Canvas output (default)

Unless `--no-canvas` flag is provided:

1. Use the **Write tool** to save to `~/.claude/canvas/calendar-<timestamp>.md`
   - Example: `calendar-2026-01-08-2245.md`
   - Format: `calendar-YYYY-MM-DD-HHmm.md`

The PostToolUse hook will automatically launch mac-canvas GUI and select the latest session.

## Use Cases

1. **Quick view**: `/mac:calendar` - Text list of today's events
2. **Visual planning**: `/mac:calendar --widget` - Interactive day view
3. **Week overview**: `/mac:calendar --widget --week` - See the week ahead
4. **Monthly planning**: `/mac:calendar --widget --month` - Month calendar

DO NOT:
- Use idag (use mac-calendar)
- Call /mac:canvas skill
- Run mac-canvas manually
