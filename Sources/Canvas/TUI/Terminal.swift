import Foundation

class Terminal {
    private var originalTermios: termios?
    private(set) var width: Int = 80
    private(set) var height: Int = 24

    static let shared = Terminal()

    private init() {
        updateSize()
        setupSignalHandler()
    }

    // MARK: - Raw Mode

    func enableRawMode() {
        var raw = termios()
        tcgetattr(STDIN_FILENO, &raw)
        originalTermios = raw

        raw.c_lflag &= ~(UInt(ECHO | ICANON | ISIG | IEXTEN))
        raw.c_iflag &= ~(UInt(IXON | ICRNL | BRKINT | INPCK | ISTRIP))
        raw.c_oflag &= ~(UInt(OPOST))
        raw.c_cflag |= UInt(CS8)

        raw.c_cc.16 = 0  // VMIN
        raw.c_cc.17 = 1  // VTIME (100ms timeout)

        tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw)

        // Hide cursor and enable alternate screen
        write(ANSI.hideCursor)
        write(ANSI.alternateScreenOn)
        write(ANSI.enableMouse)
    }

    func disableRawMode() {
        // Restore terminal
        write(ANSI.disableMouse)
        write(ANSI.alternateScreenOff)
        write(ANSI.showCursor)
        write(ANSI.reset)

        if var original = originalTermios {
            tcsetattr(STDIN_FILENO, TCSAFLUSH, &original)
        }
    }

    // MARK: - Size

    func updateSize() {
        var ws = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0 {
            width = Int(ws.ws_col)
            height = Int(ws.ws_row)
        }
    }

    private func setupSignalHandler() {
        signal(SIGWINCH) { _ in
            Terminal.shared.updateSize()
        }
    }

    // MARK: - Output

    func write(_ text: String) {
        print(text, terminator: "")
        fflush(stdout)
    }

    func moveCursor(to row: Int, col: Int) {
        write(ANSI.moveCursor(row: row, col: col))
    }

    func clear() {
        write(ANSI.clearScreen)
        moveCursor(to: 1, col: 1)
    }

    func clearLine() {
        write(ANSI.clearLine)
    }

    // MARK: - Input

    func readKey() -> KeyCode {
        var buffer = [UInt8](repeating: 0, count: 6)
        let bytesRead = read(STDIN_FILENO, &buffer, buffer.count)

        if bytesRead <= 0 {
            return .none
        }

        // Single character
        if bytesRead == 1 {
            let char = buffer[0]
            switch char {
            case 0x1B: return .escape
            case 0x0D: return .enter
            case 0x09: return .tab
            case 0x7F: return .backspace
            case 0x01...0x1A: return .ctrl(Character(UnicodeScalar(char + 0x60)))
            default: return .char(Character(UnicodeScalar(char)))
            }
        }

        // Escape sequences
        if buffer[0] == 0x1B {
            if buffer[1] == 0x5B {  // CSI [
                switch buffer[2] {
                case 0x41: return .up
                case 0x42: return .down
                case 0x43: return .right
                case 0x44: return .left
                case 0x48: return .home
                case 0x46: return .end
                case 0x35: return buffer[3] == 0x7E ? .pageUp : .none
                case 0x36: return buffer[3] == 0x7E ? .pageDown : .none
                default: break
                }
            } else if buffer[1] == 0x4F {  // SS3 O
                switch buffer[2] {
                case 0x48: return .home
                case 0x46: return .end
                default: break
                }
            }
        }

        return .char(Character(UnicodeScalar(buffer[0])))
    }
}

enum KeyCode: Equatable {
    case none
    case char(Character)
    case ctrl(Character)
    case escape
    case enter
    case tab
    case backspace
    case up
    case down
    case left
    case right
    case home
    case end
    case pageUp
    case pageDown
}

// MARK: - ANSI Escape Codes

enum ANSI {
    static let reset = "\u{001B}[0m"
    static let bold = "\u{001B}[1m"
    static let dim = "\u{001B}[2m"
    static let italic = "\u{001B}[3m"
    static let underline = "\u{001B}[4m"
    static let strikethrough = "\u{001B}[9m"
    static let inverse = "\u{001B}[7m"

    static let hideCursor = "\u{001B}[?25l"
    static let showCursor = "\u{001B}[?25h"

    static let clearScreen = "\u{001B}[2J"
    static let clearLine = "\u{001B}[2K"

    static let alternateScreenOn = "\u{001B}[?1049h"
    static let alternateScreenOff = "\u{001B}[?1049l"

    static let enableMouse = "\u{001B}[?1000h\u{001B}[?1006h"
    static let disableMouse = "\u{001B}[?1000l\u{001B}[?1006l"

    static func moveCursor(row: Int, col: Int) -> String {
        "\u{001B}[\(row);\(col)H"
    }

    static func fg(_ color: Color) -> String {
        "\u{001B}[38;5;\(color.code)m"
    }

    static func bg(_ color: Color) -> String {
        "\u{001B}[48;5;\(color.code)m"
    }

    static func rgb(r: Int, g: Int, b: Int) -> String {
        "\u{001B}[38;2;\(r);\(g);\(b)m"
    }

    static func bgRgb(r: Int, g: Int, b: Int) -> String {
        "\u{001B}[48;2;\(r);\(g);\(b)m"
    }
}

enum Color {
    case black, red, green, yellow, blue, magenta, cyan, white
    case brightBlack, brightRed, brightGreen, brightYellow
    case brightBlue, brightMagenta, brightCyan, brightWhite
    case custom(Int)

    var code: Int {
        switch self {
        case .black: return 0
        case .red: return 1
        case .green: return 2
        case .yellow: return 3
        case .blue: return 4
        case .magenta: return 5
        case .cyan: return 6
        case .white: return 7
        case .brightBlack: return 8
        case .brightRed: return 9
        case .brightGreen: return 10
        case .brightYellow: return 11
        case .brightBlue: return 12
        case .brightMagenta: return 13
        case .brightCyan: return 14
        case .brightWhite: return 15
        case .custom(let code): return code
        }
    }
}
