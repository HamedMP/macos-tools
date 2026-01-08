# macos-tools - Task List

## Completed Tasks

### Session: 2026-01-08

#### Core CLI Development
- [x] Create mac-notes Swift package with SQLite-based search
- [x] Implement NotesDatabase.swift (listNotes, searchNotes, listFolders)
- [x] Add export command for Notes (AppleScript for full content)
- [x] Create mac-messages Swift package
- [x] Implement MessagesDatabase.swift (listChats, searchMessages, getHistory)
- [x] Add send command with confirmation prompt for mac-messages
- [x] Create mac-mail Swift package
- [x] Implement MailDatabase.swift with complex joins
- [x] Add list, search, unread, from, attachments commands for mac-mail
- [x] Add send command with confirmation prompt for mac-mail

#### Project Organization
- [x] Reorganize packages to ~/dev/products/macos-tools/
- [x] Integrate mac-notes, mac-messages, mac-mail into monorepo
- [x] Update Package.swift with shared dependencies
- [x] Replace AppleScript-based Notes with SQLite version

#### Distribution
- [x] Commit all changes to git
- [x] Create v1.1.0 release tag
- [x] Push to GitHub (HamedMP/macos-tools)
- [x] Create GitHub release with release notes

## Completed

### Homebrew Formula Update
- [x] Get SHA256 of v1.1.0 tarball (d6ace8612c0719dddef162e41614e941046fdae1a18dcb238bfd6ad005ca4ae7)
- [x] Update hamedmp/homebrew-tap/Formula/macos-tools.rb
- [x] Test: `brew upgrade hamedmp/tap/macos-tools`

### CLI Testing (2026-01-08)

| Tool | Command | Status | Performance |
|------|---------|--------|-------------|
| mac-notes | list | ✅ Pass | 13ms |
| mac-notes | search | ✅ Pass | 13ms |
| mac-messages | list | ✅ Pass | 17ms |
| mac-messages | search | ✅ Pass | 17ms |
| mac-messages | history | ✅ Pass | - |
| mac-mail | list | ✅ Pass | 46ms |
| mac-mail | search | ✅ Pass | 46ms |
| mac-mail | unread | ✅ Pass | - |
| mac-mail | attachments | ✅ Pass | - |
| mac-contacts | list | ✅ Pass | - |
| mac-contacts | search | ✅ Pass | - |
| mac-focus | status | ✅ Pass | - |
| mac-music | now | ✅ Pass | - |

## Pending Tasks

### Documentation
- [x] Create specs/001-init/spec.md (functional requirements)
- [x] Create specs/001-init/plan.md (implementation plan)
- [x] Create specs/001-init/tasks.md (this file)
- [ ] Update README.md with new commands
- [ ] Add CHANGELOG.md

### Claude Code Plugin - Setup & Basic Commands
- [ ] Create /mac:setup command (checks tools, shows brew install)
- [ ] Create /mac:calendar command (uses idag)
- [ ] Create /mac:notes command
- [ ] Create /mac:notes:search command
- [ ] Create /mac:messages command
- [ ] Create /mac:messages:search command
- [ ] Create /mac:mail command
- [ ] Create /mac:mail:unread command
- [ ] Create /mac:mail:from command

### Claude Code Plugin - Configuration
- [ ] Create /mac:config command (select sources: calendar, mail, messages, notes)
- [ ] Store config in ~/.claude/mac-config.json
- [ ] Add default configuration on first run

### Claude Code Plugin - Productivity Commands
- [ ] Create /mac:daily command (raw data from configured sources)
- [ ] Create /mac:briefing command with optional query focus
  - Default: unread emails, upcoming events, recent messages
  - With query: filter all sources by topic (e.g., "receipts", "project alpha")
  - Output: summary, action items, deadlines, follow-ups, priorities
- [ ] Create /mac:weekly command (week overview with insights)
- [ ] Create /mac:todo:view command (read todos from Notes)
- [ ] Create /mac:todo:add command (add todo to Notes via AppleScript)

## Backlog

### Additional CLI Features
- [ ] Add --sort option to mac-notes
- [ ] Add --folder filter to mac-notes
- [ ] Add --json output format to all tools
- [ ] Add --since date filter to mac-messages and mac-mail

### New Tools
- [ ] mac-safari - Bookmarks/history search
- [ ] mac-photos - Photo metadata search
- [ ] mac-screentime - App usage stats

### Performance
- [ ] Add search index caching
- [ ] Implement parallel queries

## Blockers / Issues

None currently.

## Notes

### Database Schemas Discovered

**Apple Notes (NoteStore.sqlite)**
- ZICCLOUDSYNCINGOBJECT: notes, folders
- ZICNOTEDATA: note content (gzipped protobuf)
- Uses Core Data timestamps (seconds since 2001-01-01)

**iMessage (chat.db)**
- messages: message content and metadata
- chat: conversations
- handle: contacts
- chat_message_join, chat_handle_join: relationships
- Uses nanoseconds since 2001-01-01

**Apple Mail (Envelope Index)**
- messages: email metadata (subject/sender are foreign keys!)
- subjects: subject text
- senders: sender references
- sender_addresses: links senders to addresses
- addresses: email addresses with names
- Uses Unix timestamps (seconds since 1970)
