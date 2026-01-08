---
description: Search emails by keyword
arguments:
  - name: query
    description: Search query
    required: true
allowed-tools: Bash
---

Search emails for the given query.

```bash
mac-mail search "<query>" --limit 30
```

Searches in subject, sender name, and email address.

Present results showing sender, subject, date, and read status.
