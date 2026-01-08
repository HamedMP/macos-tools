---
description: List recent emails from Apple Mail
allowed-tools: Bash
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
