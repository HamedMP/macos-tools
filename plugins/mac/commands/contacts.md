---
description: Search macOS Contacts
arguments:
  - name: query
    description: Name or keyword to search for
    required: false
  - name: --canvas
    description: Send output to mac-canvas for interactive viewing
    required: false
allowed-tools: Bash, Write
---

Run `mac-contacts` to list or search contacts.

Available commands:
- `mac-contacts` - list contacts
- `mac-contacts search <name>` - search by name

Present contact info clearly with name, company, email, and phone.

## Canvas Output

If the user includes `--canvas` flag:

1. Run the command and capture the output
2. Format as markdown:
```markdown
# Contacts

## Contact Name
- **Company:** Company name
- **Email:** email@example.com
- **Phone:** +1 234 567 890
```

3. Write to canvas file:
```bash
mkdir -p ~/.claude/canvas
cat > ~/.claude/canvas/contacts-$(date +%Y%m%d-%H%M).md << 'EOF'
[formatted contacts output]
EOF
```

4. Launch canvas if not running:
```bash
if ! pgrep -x mac-canvas > /dev/null; then
    ${CLAUDE_PLUGIN_ROOT}/hooks/launch-canvas.sh
fi
```
