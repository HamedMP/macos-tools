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

2. **Commit and push tag**:
   ```bash
   git add -A && git commit -m "Release vX.Y.Z"
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main --tags
   ```

3. **Wait for GitHub Actions** - The workflow will:
   - Build arm64 binaries (macos-14 runner)
   - Build x86_64 binaries (macos-13 runner)
   - Create release with both zips attached

4. **Update Homebrew formula** (in homebrew-tap repo):
   ```bash
   # Wait for release to be created, then get SHA256
   curl -sL https://github.com/HamedMP/macos-tools/releases/download/vX.Y.Z/macos-tools-vX.Y.Z-arm64.zip | shasum -a 256

   # Update Formula/macos-tools.rb:
   # - url to new version
   # - sha256 hash
   # - version number
   # Commit and push
   ```

## Project Structure

- `.claude-plugin/marketplace.json` - Marketplace configuration
- `plugins/mac/` - macOS system tools plugin
- `plugins/work/` - Productivity tools plugin
- `Sources/` - Swift source files for CLI tools
