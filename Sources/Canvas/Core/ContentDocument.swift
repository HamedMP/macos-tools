import Foundation

struct ContentDocument {
    var sections: [Section]
    var title: String?
    var rawMarkdown: String

    init(sections: [Section] = [], title: String? = nil, rawMarkdown: String = "") {
        self.sections = sections
        self.title = title
        self.rawMarkdown = rawMarkdown
    }

    var isEmpty: Bool {
        sections.isEmpty && rawMarkdown.isEmpty
    }
}

struct Section: Identifiable {
    let id: String
    var type: SectionType
    var title: String?
    var content: [ContentBlock]
    var isExpanded: Bool = true
    var isSelected: Bool = false

    init(id: String = UUID().uuidString, type: SectionType, title: String? = nil, content: [ContentBlock] = []) {
        self.id = id
        self.type = type
        self.title = title
        self.content = content
    }
}

enum SectionType {
    case heading(level: Int)
    case paragraph
    case table
    case codeBlock(language: String?)
    case list(ordered: Bool)
    case checklist
    case blockquote
    case thematicBreak
}

enum ContentBlock {
    case text(AttributedText)
    case table(Table)
    case codeBlock(code: String, language: String?)
    case list(items: [ListItem])
    case checklist(items: [ChecklistItem])
    case image(alt: String, url: String)
    case link(text: String, url: String)
    case lineBreak
}

struct AttributedText {
    var text: String
    var styles: [TextStyle]

    init(_ text: String, styles: [TextStyle] = []) {
        self.text = text
        self.styles = styles
    }
}

enum TextStyle {
    case bold
    case italic
    case strikethrough
    case code
    case link(url: String)
    case heading(level: Int)
}

struct Table {
    var headers: [String]
    var rows: [[String]]
    var alignments: [TableAlignment]

    enum TableAlignment {
        case left, center, right
    }
}

struct ListItem {
    var content: AttributedText
    var children: [ListItem]
    var depth: Int
}

struct ChecklistItem {
    var content: AttributedText
    var isChecked: Bool
    var depth: Int
}

extension ContentDocument {
    func toMarkdown() -> String {
        rawMarkdown
    }

    func toPlainText() -> String {
        var lines: [String] = []

        for section in sections {
            if let title = section.title {
                lines.append(title)
                lines.append("")
            }

            for block in section.content {
                switch block {
                case .text(let attr):
                    lines.append(attr.text)
                case .table(let table):
                    lines.append(table.headers.joined(separator: " | "))
                    for row in table.rows {
                        lines.append(row.joined(separator: " | "))
                    }
                case .codeBlock(let code, _):
                    lines.append(code)
                case .list(let items):
                    for item in items {
                        let indent = String(repeating: "  ", count: item.depth)
                        lines.append("\(indent)- \(item.content.text)")
                    }
                case .checklist(let items):
                    for item in items {
                        let checkbox = item.isChecked ? "[x]" : "[ ]"
                        lines.append("\(checkbox) \(item.content.text)")
                    }
                case .image(let alt, _):
                    lines.append("[Image: \(alt)]")
                case .link(let text, _):
                    lines.append(text)
                case .lineBreak:
                    lines.append("")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
