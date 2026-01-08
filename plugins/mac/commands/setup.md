---
description: Check if macos-tools CLI are installed and show setup instructions
allowed-tools: Bash
---

Check if the macos-tools CLI binaries are installed by running these commands:

```bash
which mac-notes && which mac-messages && which mac-mail && which mac-contacts && which mac-calendar
```

If any are missing, show the user the installation command:

```
brew install hamedmp/tap/macos-tools
```

This installs all tools including mac-calendar.

Also check if Full Disk Access is granted (required for Messages and Mail):
- Messages database: `~/Library/Messages/chat.db`
- Mail database: `~/Library/Mail/V*/MailData/Envelope Index`

If the databases aren't readable, tell the user:
```
For mac-messages and mac-mail to work, grant Full Disk Access:
System Settings > Privacy & Security > Full Disk Access > Add your terminal app
```

Report status of each tool:
- mac-notes: installed/missing
- mac-messages: installed/missing + FDA status
- mac-mail: installed/missing + FDA status
- mac-contacts: installed/missing
- mac-focus: installed/missing
- mac-music: installed/missing
- mac-calendar (calendar): installed/missing
