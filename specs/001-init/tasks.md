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

## In Progress

### Homebrew Formula Update
- [ ] Get SHA256 of v1.1.0 tarball
- [ ] Update hamedmp/homebrew-tap/Formula/macos-tools.rb
- [ ] Test: `brew upgrade hamedmp/tap/macos-tools`

## Pending Tasks

### Documentation
- [x] Create specs/001-init/spec.md (functional requirements)
- [x] Create specs/001-init/plan.md (implementation plan)
- [x] Create specs/001-init/tasks.md (this file)
- [ ] Update README.md with new commands
- [ ] Add CHANGELOG.md

### Claude Code Plugin - Basic Commands
- [ ] Create /mac:calendar command (uses idag)
- [ ] Create /mac:notes command
- [ ] Create /mac:notes:search command
- [ ] Create /mac:messages command
- [ ] Create /mac:messages:search command
- [ ] Create /mac:mail command
- [ ] Create /mac:mail:unread command
- [ ] Create /mac:mail:from command

### Claude Code Plugin - Productivity Commands
- [ ] Create /mac:daily command (overview)
- [ ] Create /mac:briefing command (AI summary)
- [ ] Create /mac:weekly command
- [ ] Create /mac:todo:view command
- [ ] Create /mac:todo:add command
- [ ] Create /mac:todo:generate command

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
