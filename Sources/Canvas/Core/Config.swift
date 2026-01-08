import Foundation

struct CanvasConfig: Codable {
    var mode: String = "tui"
    var theme: String = "auto"
    var tui: TUIConfig = TUIConfig()
    var gui: GUIConfig = GUIConfig()

    struct TUIConfig: Codable {
        var colorScheme: String = "dark"
        var scrollSpeed: Int = 3
        var showLineNumbers: Bool = false
    }

    struct GUIConfig: Codable {
        var windowX: Int = 100
        var windowY: Int = 100
        var windowWidth: Int = 600
        var windowHeight: Int = 800
        var opacity: Double = 1.0
        var alwaysOnTop: Bool = false
    }

    static var canvasDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude")
            .appendingPathComponent("canvas")
    }

    static var configFile: URL {
        canvasDirectory.appendingPathComponent("config.json")
    }

    static func load() throws -> CanvasConfig {
        let configPath = configFile

        if FileManager.default.fileExists(atPath: configPath.path) {
            let data = try Data(contentsOf: configPath)
            return try JSONDecoder().decode(CanvasConfig.self, from: data)
        }

        return CanvasConfig()
    }

    func save() throws {
        try FileManager.default.createDirectory(
            at: Self.canvasDirectory,
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: Self.configFile)
    }
}
