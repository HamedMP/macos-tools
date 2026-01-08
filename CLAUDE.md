# macos-tools

macOS system tools and AI-powered productivity assistants for Claude Code.

## Plugins

This marketplace contains two plugins:

- **`mac`** - System tools: Calendar, Mail, Messages, Notes, Contacts, Music
- **`work`** - Productivity: Daily briefings, weekly reviews, work assistance

## Release Checklist

**IMPORTANT: Sync ALL versions before tagging!**

When creating a new release:

1. **Sync plugin versions** - Update to same version in:
   - `plugins/mac/.claude-plugin/plugin.json`
   - `plugins/work/.claude-plugin/plugin.json`
   - `.claude-plugin/marketplace.json`

2. **Commit and tag**:
   ```bash
   git add -A && git commit -m "Bump to vX.Y.Z"
   git tag -a vX.Y.Z -m "Release description"
   git push origin main --tags
   ```

3. **Update Homebrew formula** (in homebrew-tap repo):
   ```bash
   # Get SHA256 of new release
   curl -sL https://github.com/HamedMP/macos-tools/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256

   # Update Formula/macos-tools.rb with new version and SHA256
   # Commit and push
   ```

4. GitHub Actions will automatically create the release

## Project Structure

- `.claude-plugin/marketplace.json` - Marketplace configuration
- `plugins/mac/` - macOS system tools plugin
- `plugins/work/` - Productivity tools plugin
- `Sources/` - Swift source files for CLI tools
