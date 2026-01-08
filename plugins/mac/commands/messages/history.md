---
description: Get message history with a specific contact
arguments:
  - name: contact
    description: Contact phone number, email, or name
    required: true
allowed-tools: Bash
---

Get message history with a specific contact.

```bash
mac-messages history "<contact>" --limit 50
```

Present the conversation in chronological order, clearly showing who sent each message (Me vs contact).
