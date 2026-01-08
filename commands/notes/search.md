---
description: Search Apple Notes by keyword
arguments:
  - name: query
    description: Search query
    required: true
allowed-tools: Bash
---

Search Apple Notes for the given query.

```bash
mac-notes search "<query>" --limit 20
```

Present results showing note title, folder, and snippet.
