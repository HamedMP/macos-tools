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

### 3.1 Setup & Basic Commands
- [ ] `/mac:setup` - Check if tools installed, show brew install command
- [ ] `/mac:calendar` - Show today's events
- [ ] `/mac:notes` - List recent notes
- [ ] `/mac:notes search <query>` - Search notes
- [ ] `/mac:messages` - List recent conversations
- [ ] `/mac:messages search <query>` - Search messages
- [ ] `/mac:mail` - List recent emails
- [ ] `/mac:mail:unread` - Unread emails

### 3.2 Integrated Productivity Commands
- [ ] `/mac:config` - Configure sources for productivity commands (one-time setup)
- [ ] `/mac:daily` - Raw data overview from configured sources
- [ ] `/mac:briefing [query]` - AI-generated summary (default: unread mail, upcoming events)
  - Optional query to focus on specific topic (e.g., "receipts", "project alpha")
  - Output: executive summary, action items, deadlines, follow-ups, priorities
- [ ] `/mac:weekly` - Week overview with insights
- [ ] `/mac:todo:view` - View todos from Notes
- [ ] `/mac:todo:add <text>` - Add todo to Notes

### 3.3 Configuration System
Store user preferences in `~/.claude/mac-config.json`:
- Which sources to include (calendar, mail, messages, notes)
- Limits for each source (how many items to show)
- Briefing preferences (generate todos, summary style)

### 3.4 Command Structure
```
# Setup
/mac:setup          # Check tools installed
/mac:config         # Configure sources (one-time)

# Individual Tools
/mac:calendar
/mac:notes
/mac:notes:search
/mac:messages
/mac:messages:search
/mac:messages:send
/mac:mail
/mac:mail:unread
/mac:mail:from
/mac:contacts
/mac:focus
/mac:music

# Productivity (uses configured sources)
/mac:daily          # Today's overview
/mac:briefing       # AI summary + action items
/mac:weekly         # Week overview

# Todo Management
/mac:todo:view
/mac:todo:add
/mac:todo:generate
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
