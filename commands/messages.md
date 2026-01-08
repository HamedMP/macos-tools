---
description: List recent iMessage conversations
allowed-tools: Bash
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
