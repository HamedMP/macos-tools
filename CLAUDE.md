# macos-tools

CLI tools for macOS productivity - integrates with Calendar, Mail, Messages, Notes, and Contacts.

## Release Checklist

When creating a new release:

1. Update version in `.claude-plugin/plugin.json`
2. Commit changes
3. Create and push tag: `git tag vX.Y.Z && git push origin vX.Y.Z`
4. GitHub Actions will automatically create the release

## Project Structure

- `.claude-plugin/` - Claude Code plugin configuration
- `src/` - Swift source files for CLI tools
- `scripts/` - Build and installation scripts
