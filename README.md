# macos-tools

<p align="center">
  <img src="assets/banner.svg" alt="macos-tools banner" width="100%">
</p>

<p align="center">
  <a href="https://github.com/HamedMP/macos-tools/stargazers"><img src="https://img.shields.io/github/stars/HamedMP/macos-tools?style=flat&color=yellow" alt="Stars"></a>
  <a href="https://github.com/HamedMP/macos-tools/releases"><img src="https://img.shields.io/github/v/release/HamedMP/macos-tools?style=flat&color=blue" alt="Release"></a>
  <a href="https://github.com/HamedMP/macos-tools/blob/main/LICENSE"><img src="https://img.shields.io/github/license/HamedMP/macos-tools?style=flat" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey?style=flat&logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat&logo=swift" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/homebrew-hamedmp%2Ftap-brown?style=flat&logo=homebrew" alt="Homebrew">
</p>

<p align="center">
  <strong>Fast CLI tools for macOS Calendar, Notes, Mail, Messages, and more.</strong><br>
  Direct database access - 1000x faster than AppleScript.
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
| `mac-calendar` | Query Calendar events | 15ms |
| `mac-notes` | Search Apple Notes | 14ms |
| `mac-messages` | Search iMessages | 17ms |
| `mac-mail` | Search Apple Mail | 22ms |
| `mac-contacts` | Search Contacts | - |
| `mac-focus` | Focus mode control | - |
| `mac-music` | Apple Music / Spotify | - |
| `mac-canvas` | Interactive markdown viewer | - |

### Calendar

```bash
mac-calendar                   # Today's events
mac-calendar tomorrow          # Tomorrow's events
mac-calendar week              # Next 7 days
mac-calendar month             # Next 30 days
mac-calendar --json            # Output as JSON
```

### Notes

```bash
mac-notes                      # List recent notes
mac-notes search "meeting"     # Search notes
mac-notes create "Title"       # Create new note
mac-notes create "Title" -b "Body content"  # With body
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

### Canvas (Interactive Viewer)

```bash
mac-canvas watch               # Watch ~/.claude/canvas/ for changes
mac-canvas watch file.md       # Watch specific file
mac-canvas --gui               # Open in GUI mode (floating panel)
```

Keyboard shortcuts in TUI mode:
- `j/k` - Scroll up/down
- `Tab` - Jump to next section
- `c` - Copy current section
- `s` - Save to Apple Notes
- `e` - Compose email
- `[/]` - Focus sidebar/content
- `?` - Show help

## Claude Code Plugin

Install the plugin to use `/mac:*` commands in Claude Code.

**Option 1: Via `/plugin` command (recommended)**
```
/plugin marketplace add hamedmp/macos-tools
/plugin install mac@claude-macos-tools
```

**Option 2: Via CLI**
```bash
claude plugin marketplace add hamedmp/macos-tools
claude plugin install mac@claude-macos-tools
```

### Basic Commands

```
/mac:setup           Check if CLI tools installed
/mac:calendar        Today's events
/mac:notes           Recent notes
/mac:notes:search    Search notes
/mac:notes:create    Create a new note
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

Grant **Calendar Access** for mac-calendar (prompted automatically on first use).

## Requirements

- macOS 13.0+ (Ventura)
- Swift 5.9+
- Full Disk Access (for Messages/Mail)

## License

MIT
