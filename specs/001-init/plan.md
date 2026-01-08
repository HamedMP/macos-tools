# macos-tools - Implementation Plan

## Phase 1: Core CLI Tools (COMPLETED)

### 1.1 mac-notes - SQLite Migration
- [x] Research Apple Notes SQLite schema
- [x] Implement NotesDatabase.swift with direct SQLite queries
- [x] Add list, search, folders commands
- [x] Add export command (uses AppleScript for full content)
- [x] Add --limit option

### 1.2 mac-messages
- [x] Research iMessage SQLite schema (chat.db)
- [x] Implement MessagesDatabase.swift
- [x] Add list, search, history commands
- [x] Add send command with confirmation prompt
- [x] Add --limit and --sort options

### 1.3 mac-mail
- [x] Research Apple Mail SQLite schema (Envelope Index)
- [x] Implement MailDatabase.swift with proper joins (subjects, addresses, senders)
- [x] Add list, search, unread, from, attachments commands
- [x] Add send command with confirmation prompt
- [x] Add --limit and --sort options

### 1.4 Monorepo Setup
- [x] Reorganize into ~/dev/products/macos-tools/
- [x] Update Package.swift with shared dependencies
- [x] Consolidate Sources/ folder structure

## Phase 2: Distribution (IN PROGRESS)

### 2.1 GitHub Release
- [x] Commit all changes
- [x] Create v1.1.0 release tag
- [x] Push to GitHub
- [x] Create GitHub release with notes

### 2.2 Homebrew Formula
- [ ] Get SHA256 of release tarball
- [ ] Update hamedmp/homebrew-tap formula
- [ ] Test installation: `brew install hamedmp/tap/macos-tools`
- [ ] Verify all binaries work

## Phase 3: Claude Code Plugin (PLANNED)

### 3.1 Basic Commands
- [ ] `/mac:calendar` - Show today's events
- [ ] `/mac:notes` - List recent notes
- [ ] `/mac:notes search <query>` - Search notes
- [ ] `/mac:messages` - List recent conversations
- [ ] `/mac:messages search <query>` - Search messages
- [ ] `/mac:mail` - List recent emails
- [ ] `/mac:mail:unread` - Unread emails

### 3.2 Integrated Productivity Commands
- [ ] `/mac:daily` - Daily overview combining calendar, emails, messages
- [ ] `/mac:briefing` - AI-generated morning briefing
- [ ] `/mac:weekly` - Week overview with insights
- [ ] `/mac:todo:view` - View todos from Notes
- [ ] `/mac:todo:add <text>` - Add todo to Notes
- [ ] `/mac:todo:generate` - Generate todos from calendar/emails

### 3.3 Command Structure
```
/mac:notes
/mac:notes:search
/mac:messages
/mac:messages:search
/mac:messages:send
/mac:mail
/mac:mail:unread
/mac:mail:from
/mac:todo:view
/mac:todo:add
/mac:todo:generate
/mac:daily
/mac:briefing
/mac:weekly
```

## Phase 4: Future Enhancements (BACKLOG)

### 4.1 Additional Tools
- [ ] mac-safari - Bookmarks, history, reading list
- [ ] mac-photos - Photo metadata search
- [ ] mac-screentime - App usage stats

### 4.2 Advanced Features
- [ ] Fuzzy search across all tools
- [ ] Natural language date queries ("last week")
- [ ] Export to various formats (JSON, CSV)
- [ ] Watch mode for real-time updates

### 4.3 Performance Optimizations
- [ ] Index caching for faster repeated queries
- [ ] Parallel queries across multiple databases
- [ ] Incremental sync detection

## Technical Decisions

### Why SQLite over AppleScript?
- **Speed**: 14-22ms vs seconds/minutes
- **Reliability**: No app activation required
- **Consistency**: Same data format across queries

### Why Swift over other languages?
- Native macOS integration
- Type safety for database schemas
- Swift Argument Parser for CLI
- Single binary distribution

### Why monorepo?
- Shared dependencies (SQLite, ArgumentParser)
- Consistent versioning
- Easier maintenance
- Single Homebrew formula
