---
description: List recent emails from Apple Mail
arguments:
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Run `mac-mail list` to show recent emails.

Available commands:
- `mac-mail` or `mac-mail list` - recent emails
- `mac-mail search <query>` - search emails
- `mac-mail unread` - unread emails only
- `mac-mail from <sender>` - emails from sender
- `mac-mail attachments` - emails with attachments

Options:
- `--limit N` - limit results (default: 20)
- `--sort date|sender|subject` - sort order

Present the emails in a clean format showing sender, subject, and date.

## Canvas Output

If the user includes `--canvas` flag:

1. Run the command and capture the output
2. Format as markdown with a table:
```markdown
# Mail

| From | Subject | Date |
|------|---------|------|
| sender | subject line | date |
```

3. Write to canvas file:
```bash
mkdir -p ~/.claude/canvas
cat > ~/.claude/canvas/mail-$(date +%Y%m%d-%H%M).md << 'EOF'
[formatted mail output]
EOF
```

4. Launch canvas if not running:
```bash
if ! pgrep -x mac-canvas > /dev/null; then
    ${CLAUDE_PLUGIN_ROOT}/hooks/launch-canvas.sh
fi
```
