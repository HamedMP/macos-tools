---
description: List recent iMessage conversations
arguments:
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Run `mac-messages list` to show recent conversations.

Available commands:
- `mac-messages` or `mac-messages list` - recent conversations
- `mac-messages search <query>` - search messages
- `mac-messages history <contact>` - messages with a contact
- `mac-messages send <phone> "text"` - send message (requires confirmation)

Options:
- `--limit N` - limit results (default: 20)
- `--sort date|sender` - sort order

Present the conversations in a clean format showing contact name/number and last message preview.

## Canvas Output

If the user includes `--canvas` flag:

1. Run the command and capture the output
2. Format as markdown:
```markdown
# Messages

| Contact | Last Message | Time |
|---------|--------------|------|
| Name | Message preview... | 2:30 PM |
```

3. Write to canvas file:
```bash
mkdir -p ~/.claude/canvas
cat > ~/.claude/canvas/messages-$(date +%Y%m%d-%H%M).md << 'EOF'
[formatted messages output]
EOF
```

4. Launch canvas if not running:
```bash
if ! pgrep -x mac-canvas > /dev/null; then
    ${CLAUDE_PLUGIN_ROOT}/hooks/launch-canvas.sh
fi
```
