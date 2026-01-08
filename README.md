# macos-tools

A collection of CLI tools for macOS system integrations, plus a Claude Code plugin.

## Installation

### Homebrew

```bash
brew install hamedmp/tap/macos-tools
```

### From source

```bash
git clone https://github.com/hamedmp/macos-tools.git
cd macos-tools
swift build -c release
sudo cp .build/release/mac-* /usr/local/bin/
```

### Claude Code Plugin

```bash
/plugin marketplace add hamedmp/macos-tools
/plugin install mac@macos-tools
```

## Tools

| Tool | Command | Description |
|------|---------|-------------|
| Calendar | `idag` | Calendar events (separate package) |
| Reminders | `mac-reminders` | List/manage reminders |
| Notes | `mac-notes` | Search Apple Notes |
| Contacts | `mac-contacts` | Search contacts |
| Focus | `mac-focus` | Focus mode status |
| Music | `mac-music` | Control Apple Music/Spotify |

## Claude Code Commands

After installing the plugin:

```
/mac:calendar    - Today's events
/mac:reminders   - Pending reminders
/mac:notes       - Recent notes
/mac:contacts    - Search contacts
/mac:focus       - Focus mode status
/mac:music       - Now playing
```

## CLI Usage

### Reminders

```bash
mac-reminders              # Pending reminders
mac-reminders completed    # Completed reminders
mac-reminders --json       # JSON output
```

### Notes

```bash
mac-notes                  # Recent notes
mac-notes search meeting   # Search notes
mac-notes folders          # List folders
```

### Contacts

```bash
mac-contacts               # List contacts
mac-contacts search John   # Search by name
```

### Music

```bash
mac-music                  # Now playing
mac-music play             # Start playback
mac-music pause            # Pause
mac-music next             # Next track
```

### Focus

```bash
mac-focus                  # Show status
mac-focus toggle           # Toggle Focus mode
```

## Permissions

First run will prompt for access. Grant in:

**System Settings > Privacy & Security**
- Reminders
- Contacts
- Calendars (for idag)

## Requirements

- macOS 13.0+
- Swift 5.9+

## License

MIT
