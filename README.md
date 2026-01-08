# macos-tools

<p align="center">
  <img src="assets/banner.svg" alt="macos-tools banner" width="100%">
</p>

<p align="center">
  <strong>Fast CLI tools for macOS Notes, Mail, Messages, and more.</strong><br>
  Direct SQLite access - 1000x faster than AppleScript.
</p>

<p align="center">
  <a href="#installation">Installation</a> |
  <a href="#cli-tools">CLI Tools</a> |
  <a href="#claude-code-plugin">Plugin</a> |
  <a href="#productivity-commands">Productivity</a>
</p>

## Installation

### Homebrew (Recommended)

```bash
brew install hamedmp/tap/macos-tools
```

### From Source

```bash
git clone https://github.com/hamedmp/macos-tools.git
cd macos-tools
swift build -c release
sudo cp .build/release/mac-* /usr/local/bin/
```

## CLI Tools

| Tool | Description | Performance |
|------|-------------|-------------|
| `mac-notes` | Search Apple Notes | 14ms |
| `mac-messages` | Search iMessages | 17ms |
| `mac-mail` | Search Apple Mail | 22ms |
| `mac-contacts` | Search Contacts | - |
| `mac-focus` | Focus mode control | - |
| `mac-music` | Apple Music / Spotify | - |

### Notes

```bash
mac-notes                      # List recent notes
mac-notes search "meeting"     # Search notes
mac-notes folders              # List folders
mac-notes export               # Export to markdown
```

### Messages

```bash
mac-messages                   # Recent conversations
mac-messages search "hello"    # Search messages
mac-messages history +1234     # Chat history with contact
mac-messages send +1234 "Hi"   # Send message (with confirmation)
```

### Mail

```bash
mac-mail                       # Recent emails
mac-mail unread                # Unread only
mac-mail search "invoice"      # Search emails
mac-mail from "john@"          # From specific sender
mac-mail attachments           # Emails with attachments
```

### Other Tools

```bash
mac-contacts search John       # Search contacts
mac-focus                      # Focus mode status
mac-music                      # Now playing
mac-music play/pause/next      # Control playback
```

## Claude Code Plugin

Install the plugin to use `/mac:*` commands in Claude Code:

```bash
claude plugin add hamedmp/macos-tools
```

### Basic Commands

```
/mac:setup           Check if CLI tools installed
/mac:calendar        Today's events
/mac:notes           Recent notes
/mac:notes:search    Search notes
/mac:messages        Recent conversations
/mac:messages:search Search messages
/mac:mail            Recent emails
/mac:mail:unread     Unread emails
/mac:contacts        Search contacts
```

### Productivity Commands

```
/mac:config          Configure which sources to include
/mac:daily           Today's overview (calendar + mail + messages)
/mac:briefing        AI summary with action items
/mac:weekly          Weekly overview with insights
/mac:todo:view       View todos from Notes
/mac:todo:add        Add todo to Notes
```

#### `/mac:briefing` - AI Daily Summary

Default behavior - summarizes your day:
```
/mac:briefing
```
- Unread emails
- Today's calendar
- Recent messages

Focus on specific topic:
```
/mac:briefing receipts        # Everything about receipts
/mac:briefing "project alpha" # Project-specific summary
```

Output includes:
- Executive summary
- Action items
- Key deadlines
- People to follow up with

## Permissions

Grant **Full Disk Access** for Messages and Mail:

**System Settings > Privacy & Security > Full Disk Access > Add your terminal**

## Requirements

- macOS 13.0+ (Ventura)
- Swift 5.9+
- Full Disk Access (for Messages/Mail)

## License

MIT
