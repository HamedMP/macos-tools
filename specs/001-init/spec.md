# macos-tools - Functional Specification

## Overview

A collection of CLI tools for fast access to macOS system data (Notes, Messages, Mail, Calendar, etc.) with a Claude Code plugin for integrated productivity workflows.

## Problem Statement

Native macOS apps (Notes, Messages, Mail) have excellent GUIs but limited CLI access. AppleScript-based solutions are slow and unreliable. Users need:
1. Fast command-line search across macOS data
2. Integration with AI assistants (Claude Code)
3. Productivity workflows combining multiple data sources

## Solution

SQLite-based CLI tools that directly query macOS app databases, providing:
- **Instant search** (14-22ms vs seconds/minutes with AppleScript)
- **Consistent interface** across all tools
- **Claude Code plugin** for AI-assisted workflows

## Functional Requirements

### Core CLI Tools

#### mac-notes
| Command | Description |
|---------|-------------|
| `mac-notes list [--limit N]` | List recent notes |
| `mac-notes search <query> [--limit N]` | Search by title/content |
| `mac-notes folders` | List all folders |
| `mac-notes export [--output PATH]` | Export to markdown |

#### mac-messages
| Command | Description |
|---------|-------------|
| `mac-messages list [--limit N]` | List recent conversations |
| `mac-messages search <query> [--limit N] [--sort date\|sender]` | Search messages |
| `mac-messages history <contact> [--limit N]` | Messages with contact |
| `mac-messages send <phone> "text" [--yes]` | Send iMessage |

#### mac-mail
| Command | Description |
|---------|-------------|
| `mac-mail list [--limit N] [--sort date\|sender\|subject]` | List recent emails |
| `mac-mail search <query> [--limit N]` | Search emails |
| `mac-mail unread [--limit N]` | Show unread emails |
| `mac-mail from <sender> [--limit N]` | Emails from sender |
| `mac-mail attachments [--limit N]` | Emails with attachments |
| `mac-mail send --to <email> --subject "..." --body "..."` | Send email |

#### mac-contacts, mac-focus, mac-music, mac-reminders
Existing tools for contacts, focus mode, music control, and reminders.

### Claude Code Plugin Commands

#### Setup & Basic Commands
| Command | Description |
|---------|-------------|
| `/mac:setup` | Check if CLI tools installed, show brew install |
| `/mac:calendar` | Today's calendar events |
| `/mac:notes` | Recent notes |
| `/mac:notes search` | Search notes |
| `/mac:messages` | Recent conversations |
| `/mac:mail` | Recent emails |
| `/mac:mail:unread` | Unread emails |

#### Integrated Productivity Commands
| Command | Description |
|---------|-------------|
| `/mac:daily` | Today's raw data (configurable sources) |
| `/mac:briefing [query]` | AI-generated summary with optional focus |
| `/mac:weekly` | Week overview with insights |
| `/mac:todo:view` | View todo items from Notes |
| `/mac:todo:add` | Add todo to Notes |
| `/mac:config` | Configure which sources to include |

#### Briefing Command Details

`/mac:briefing` generates an AI summary of your day.

**Default behavior:**
- Unread emails (since yesterday)
- Upcoming calendar events (today + tomorrow)
- Recent messages (last 24h)
- Pending reminders

**Custom focus with query:**
```
/mac:briefing receipts        # Focus on emails about receipts
/mac:briefing "project alpha" # Everything related to project alpha
/mac:briefing meetings        # Focus on meeting-related items
```

**Output includes:**
- Executive summary (2-3 sentences)
- Key action items
- Important deadlines
- People to follow up with
- Suggested priorities

#### Productivity Command Configuration

Users configure sources once via `/mac:config`:

```
/mac:config
```

Prompts user to select which sources to include in productivity commands:
- [ ] Calendar (today's events)
- [ ] Mail (unread emails)
- [ ] Messages (recent conversations)
- [ ] Notes (recent notes)
- [ ] Reminders (pending tasks)

Configuration stored in `~/.claude/mac-config.json`:
```json
{
  "daily": {
    "sources": ["calendar", "mail", "messages"],
    "mailLimit": 10,
    "messagesLimit": 5
  },
  "briefing": {
    "sources": ["calendar", "mail"],
    "generateTodos": true
  }
}
```

Default configuration includes: calendar, mail, messages.

## Non-Functional Requirements

### Performance
- Search operations: < 50ms
- List operations: < 100ms
- No background processes or daemons

### Security
- Read-only database access (except send commands)
- Confirmation prompt for send operations
- Full Disk Access required (user grants permission)

### Compatibility
- macOS 13.0+ (Ventura)
- Swift 5.9+
- Works with standard macOS app database locations

## Database Locations

| App | Database Path |
|-----|---------------|
| Notes | `~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite` |
| Messages | `~/Library/Messages/chat.db` |
| Mail | `~/Library/Mail/V*/MailData/Envelope Index` |
| Calendar | EventKit framework (not SQLite) |

## Distribution

### Homebrew
```bash
brew install hamedmp/tap/macos-tools
```

### Claude Code Plugin
```bash
/plugin marketplace add hamedmp/macos-tools
```

## Success Metrics

1. Search time < 50ms (vs minutes with AppleScript)
2. All major macOS productivity apps accessible via CLI
3. Seamless Claude Code integration for AI-assisted workflows
