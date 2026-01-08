---
description: Show emails from a specific sender
arguments:
  - name: sender
    description: Sender email or name
    required: true
allowed-tools: Bash
---

Show emails from a specific sender.

```bash
mac-mail from "<sender>" --limit 20
```

Present emails showing subject, date, and read status.
