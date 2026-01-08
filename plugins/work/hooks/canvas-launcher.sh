#!/bin/bash
# PostToolUse hook: Launch mac-canvas GUI when writing to canvas directory

LOG="/tmp/canvas-launcher.log"
echo "$(date): Hook started" >> "$LOG"
echo "CLAUDE_PLUGIN_ROOT: $CLAUDE_PLUGIN_ROOT" >> "$LOG"

# Read tool input from stdin
INPUT=$(cat)
echo "Input: $INPUT" >> "$LOG"

# Extract file_path from JSON input
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"/\1/' | tail -1)
echo "FILE_PATH: $FILE_PATH" >> "$LOG"

# Only trigger for canvas directory writes
if [[ "$FILE_PATH" != *".claude/canvas/"* ]]; then
    echo "Skipping: not canvas dir" >> "$LOG"
    exit 0
fi
if [[ "$FILE_PATH" != *.md ]]; then
    echo "Skipping: not .md file" >> "$LOG"
    exit 0
fi

# If already running, just bring to focus
if pgrep -x mac-canvas > /dev/null; then
    echo "mac-canvas running, bringing to focus..." >> "$LOG"
    osascript -e 'tell application "System Events" to set frontmost of process "mac-canvas" to true' 2>> "$LOG"
    exit 0
fi

echo "Launching mac-canvas..." >> "$LOG"

# Launch GUI canvas using osascript (works better from hook context)
osascript -e 'do shell script "/usr/local/bin/mac-canvas watch --gui > /dev/null 2>&1 &"' 2>> "$LOG"

echo "osascript exit code: $?" >> "$LOG"
exit 0
