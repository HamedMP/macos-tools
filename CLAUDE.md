# macos-tools

macOS system tools and AI-powered productivity assistants for Claude Code.

## Plugins

This marketplace contains two plugins:

- **`mac`** - System tools: Calendar, Mail, Messages, Notes, Contacts, Music
- **`work`** - Productivity: Daily briefings, weekly reviews, work assistance

## Release Checklist

When creating a new release:

1. Update versions in `plugins/mac/.claude-plugin/plugin.json` and `plugins/work/.claude-plugin/plugin.json`
2. Update version in `.claude-plugin/marketplace.json`
3. Commit changes
4. Create and push tag: `git tag vX.Y.Z && git push origin vX.Y.Z`
5. GitHub Actions will automatically create the release

## Project Structure

- `.claude-plugin/marketplace.json` - Marketplace configuration
- `plugins/mac/` - macOS system tools plugin
- `plugins/work/` - Productivity tools plugin
- `Sources/` - Swift source files for CLI tools
