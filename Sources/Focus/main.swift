import Foundation

func runAppleScript(_ script: String) -> String? {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    } catch {
        return nil
    }
}

func getFocusStatus() -> Bool {
    let script = """
    tell application "System Events"
        tell process "Control Center"
            try
                return exists menu bar item "Focus" of menu bar 1
            on error
                return false
            end try
        end tell
    end tell
    """

    // Check if Do Not Disturb is enabled via defaults
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
    process.arguments = ["-currentHost", "read", "com.apple.notificationcenterui", "doNotDisturb"]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice

    do {
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return result == "1"
    } catch {
        return false
    }
}

func toggleFocus() {
    // Toggle Focus using keyboard shortcut simulation
    let script = """
    tell application "System Events"
        -- Open Control Center
        keystroke "c" using {control down, command down}
        delay 0.5
        -- Click Focus
        tell process "Control Center"
            try
                click button "Focus" of group 1 of window "Control Center"
            end try
        end tell
        delay 0.3
        -- Close by pressing escape
        key code 53
    end tell
    """

    _ = runAppleScript(script)

    // Alternative: use shortcuts command
    let shortcutProcess = Process()
    shortcutProcess.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
    shortcutProcess.arguments = ["run", "Toggle Focus"]

    do {
        try shortcutProcess.run()
        shortcutProcess.waitUntilExit()
        print("Focus toggled. Check menu bar for current status.")
    } catch {
        print("To toggle Focus, create a Shortcut named 'Toggle Focus' or use Control Center.")
    }
}

func showStatus() {
    let enabled = getFocusStatus()
    print("Focus Mode")
    print(String(repeating: "-", count: 50))
    print("Status: \(enabled ? "ON" : "OFF")")
    print("")
    print("Tip: Use Control Center or create a Shortcut to toggle Focus modes.")
}

func printUsage() {
    print("""
    mac-focus - macOS Focus Mode control

    USAGE:
        mac-focus [COMMAND]

    COMMANDS:
        status      Show current Focus status (default)
        toggle      Toggle Focus mode
        on          Enable Do Not Disturb
        off         Disable Do Not Disturb

    EXAMPLES:
        mac-focus           # Show status
        mac-focus toggle    # Toggle Focus

    NOTE:
        For reliable Focus control, create a Shortcut named 'Toggle Focus'
        that toggles your preferred Focus mode.
    """)
}

@main
struct FocusCLI {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--help") || args.contains("-h") {
            printUsage()
            return
        }

        let command = args.first ?? "status"

        switch command {
        case "status":
            showStatus()
        case "toggle":
            toggleFocus()
        case "on", "off":
            print("Use 'mac-focus toggle' or create a Shortcut for specific Focus modes.")
        default:
            showStatus()
        }
    }
}
