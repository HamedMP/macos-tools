---
description: Compose and preview an email before sending
arguments:
  - name: to
    description: Recipient email address
    required: true
  - name: subject
    description: Email subject line
    required: true
  - name: body
    description: Email body content
    required: true
allowed-tools: Bash, Write, AskUserQuestion
---

# Compose Email Command

Create an email preview in canvas with the option to send.

## Step 1: Create email preview

Write the email preview to canvas using this exact format:

```markdown
# Email Preview

| Field | Value |
|-------|-------|
| From | (user's email - use "me" if unknown) |
| To | <to> |
| Subject | <subject> |

---

<body>

---

**Actions:** Press `E` to send via Mail.app, or `Esc` to cancel.
```

## Step 2: Write to canvas

Use the **Write tool** to save to `~/.claude/canvas/email-compose-<timestamp>.md`

Example filename: `email-compose-2026-01-08-2245.md`

The PostToolUse hook will automatically launch mac-canvas GUI.

## Step 3: Confirm before sending

After showing the preview, ask the user:

"Email preview ready in canvas. Would you like me to send it now?"

If yes, send using AppleScript:
```bash
osascript -e 'tell application "Mail"
    set newMessage to make new outgoing message with properties {subject:"<subject>", content:"<body>", visible:false}
    tell newMessage
        make new to recipient at end of to recipients with properties {address:"<to>"}
        send
    end tell
end tell'
```

## Example Usage

User: "compose an email to john@example.com about the meeting tomorrow"

1. Generate appropriate subject and body
2. Write preview to canvas
3. Ask for confirmation
4. Send if confirmed
