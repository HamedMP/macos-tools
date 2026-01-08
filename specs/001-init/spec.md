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

#### Basic Commands
| Command | Description |
|---------|-------------|
| `/mac:calendar` | Today's calendar events |
| `/mac:notes` | Recent notes |
| `/mac:notes search` | Search notes |
| `/mac:messages` | Recent conversations |
| `/mac:mail` | Recent emails |
| `/mac:mail:unread` | Unread emails |

#### Integrated Productivity Commands
| Command | Description |
|---------|-------------|
| `/mac:daily` | Today's overview (calendar + emails + messages) |
| `/mac:briefing` | Morning briefing with AI summary |
| `/mac:weekly` | Week overview with insights |
| `/mac:todo:view` | View todo items from Notes |
| `/mac:todo:add` | Add todo to Notes |
| `/mac:todo:generate` | Generate todos from calendar/emails |

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
