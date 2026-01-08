import ArgumentParser
import Foundation

@main
struct CanvasCLI: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "mac-canvas",
        abstract: "TUI/GUI viewer for macos-tools output",
        version: "1.0.0",
        subcommands: [Watch.self, Show.self, Clear.self, Config.self],
        defaultSubcommand: Watch.self
    )
}

struct Watch: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Watch canvas file and display updates"
    )

    @Flag(name: .long, help: "Use GUI mode instead of TUI")
    var gui: Bool = false

    @Option(name: .long, help: "Canvas name (for multiple sessions)")
    var name: String?

    @Option(name: .long, help: "Custom file path to watch")
    var file: String?

    func run() throws {
        let canvasDir = CanvasConfig.canvasDirectory

        // Determine canvas name: explicit > env var > parent PID (terminal session)
        let canvasName: String
        if let explicitName = name {
            canvasName = explicitName
        } else if let envSession = ProcessInfo.processInfo.environment["CANVAS_SESSION"] {
            canvasName = envSession
        } else {
            // Use parent PID to tie canvas to terminal session
            let ppid = getppid()
            canvasName = "session-\(ppid)"
        }

        let filePath = file ?? canvasDir.appendingPathComponent("\(canvasName).md").path

        // Print session info for debugging
        if ProcessInfo.processInfo.environment["DEBUG"] != nil {
            print("Canvas: \(canvasName) -> \(filePath)")
        }

        try FileManager.default.createDirectory(
            at: canvasDir,
            withIntermediateDirectories: true
        )

        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: nil)
        }

        if gui {
            // In GUI mode, let the app auto-select latest canvas unless a specific file/name was given
            if file != nil || name != nil {
                let guiApp = GUIApp(filePath: filePath)
                guiApp.run()
            } else {
                // No specific file - let GUI auto-select the latest
                let guiApp = GUIApp(filePath: nil)
                guiApp.run()
            }
        } else {
            let tuiApp = TUIApp(filePath: filePath)
            try tuiApp.run()
        }
    }
}

struct Show: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Display a markdown file once"
    )

    @Argument(help: "Markdown file to display")
    var file: String

    @Flag(name: .long, help: "Use GUI mode instead of TUI")
    var gui: Bool = false

    func run() throws {
        let content = try String(contentsOfFile: file, encoding: .utf8)
        let parser = MarkdownParser()
        let document = parser.parse(content)

        if gui {
            let guiApp = GUIApp(document: document)
            guiApp.run()
        } else {
            let renderer = ANSIRenderer()
            print(renderer.render(document))
        }
    }
}

struct Clear: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Clear canvas content"
    )

    @Option(name: .long, help: "Canvas name")
    var name: String?

    func run() throws {
        // Determine canvas name: explicit > env var > parent PID
        let canvasName: String
        if let explicitName = name {
            canvasName = explicitName
        } else if let envSession = ProcessInfo.processInfo.environment["CANVAS_SESSION"] {
            canvasName = envSession
        } else {
            let ppid = getppid()
            canvasName = "session-\(ppid)"
        }

        let filePath = CanvasConfig.canvasDirectory.appendingPathComponent("\(canvasName).md")
        try "".write(to: filePath, atomically: true, encoding: .utf8)
        print("Canvas '\(canvasName)' cleared")
    }
}

struct Config: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Configure canvas settings",
        subcommands: [ConfigSet.self, ConfigGet.self, ConfigList.self]
    )
}

struct ConfigSet: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a configuration value"
    )

    @Argument(help: "Setting name (mode, theme)")
    var key: String

    @Argument(help: "Setting value")
    var value: String

    func run() throws {
        var config = try CanvasConfig.load()

        switch key {
        case "mode":
            guard value == "tui" || value == "gui" else {
                throw ValidationError("Mode must be 'tui' or 'gui'")
            }
            config.mode = value
        case "theme":
            guard ["dark", "light", "auto"].contains(value) else {
                throw ValidationError("Theme must be 'dark', 'light', or 'auto'")
            }
            config.theme = value
        default:
            throw ValidationError("Unknown setting: \(key)")
        }

        try config.save()
        print("Set \(key) = \(value)")
    }
}

struct ConfigGet: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a configuration value"
    )

    @Argument(help: "Setting name")
    var key: String

    func run() throws {
        let config = try CanvasConfig.load()

        switch key {
        case "mode": print(config.mode)
        case "theme": print(config.theme)
        default: throw ValidationError("Unknown setting: \(key)")
        }
    }
}

struct ConfigList: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all configuration values"
    )

    func run() throws {
        let config = try CanvasConfig.load()
        print("mode: \(config.mode)")
        print("theme: \(config.theme)")
    }
}
