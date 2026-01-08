---
description: Search iMessages by keyword
arguments:
  - name: query
    description: Search query
    required: true
allowed-tools: Bash
---

Search iMessages for the given query.

```bash
mac-messages search "<query>" --limit 30
```

Options:
- `--sort date|sender` - sort results

Present results showing date, sender, and message text.
