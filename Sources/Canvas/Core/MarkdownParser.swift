import Foundation
import Markdown

class MarkdownParser {
    func parse(_ markdown: String) -> ContentDocument {
        let document = Document(parsing: markdown)
        var sections: [Section] = []
        var currentSection: Section?
        var documentTitle: String?

        for child in document.children {
            let result = processBlock(child)

            if case .heading(let level) = result.type, level <= 2 {
                // Start new section on h1/h2
                if let section = currentSection {
                    sections.append(section)
                }
                currentSection = result

                if documentTitle == nil, level == 1 {
                    documentTitle = result.title
                }
            } else if currentSection != nil {
                // Add to current section
                currentSection?.content.append(contentsOf: result.content)
            } else {
                // No section yet, create implicit one
                currentSection = Section(type: .paragraph, content: result.content)
            }
        }

        if let section = currentSection {
            sections.append(section)
        }

        return ContentDocument(
            sections: sections,
            title: documentTitle,
            rawMarkdown: markdown
        )
    }

    private func processBlock(_ markup: any Markup) -> Section {
        switch markup {
        case let heading as Heading:
            let text = extractPlainText(from: heading)
            return Section(
                type: .heading(level: heading.level),
                title: text,
                content: [.text(AttributedText(text, styles: [.heading(level: heading.level)]))]
            )

        case let paragraph as Paragraph:
            let text = processInlineMarkup(paragraph)
            return Section(type: .paragraph, content: [.text(text)])

        case let codeBlock as CodeBlock:
            return Section(
                type: .codeBlock(language: codeBlock.language),
                content: [.codeBlock(code: codeBlock.code, language: codeBlock.language)]
            )

        case let list as UnorderedList:
            let items = processUnorderedList(list)
            // Check if it's a checklist
            if items.allSatisfy({ isChecklistItem($0) }) {
                let checklistItems = items.map { item -> ChecklistItem in
                    let (isChecked, text) = parseChecklistText(item.content.text)
                    return ChecklistItem(
                        content: AttributedText(text),
                        isChecked: isChecked,
                        depth: item.depth
                    )
                }
                return Section(type: .checklist, content: [.checklist(items: checklistItems)])
            }
            return Section(type: .list(ordered: false), content: [.list(items: items)])

        case let list as OrderedList:
            let items = processOrderedList(list)
            return Section(type: .list(ordered: true), content: [.list(items: items)])

        case let table as Markdown.Table:
            let parsedTable = processTable(table)
            return Section(type: .table, content: [.table(parsedTable)])

        case let blockquote as BlockQuote:
            let text = extractPlainText(from: blockquote)
            return Section(type: .blockquote, content: [.text(AttributedText(text, styles: [.italic]))])

        case is ThematicBreak:
            return Section(type: .thematicBreak, content: [.lineBreak])

        default:
            // Fallback for unknown types
            let text = extractPlainText(from: markup)
            if !text.isEmpty {
                return Section(type: .paragraph, content: [.text(AttributedText(text))])
            }
            return Section(type: .paragraph)
        }
    }

    private func processInlineMarkup(_ markup: any Markup) -> AttributedText {
        var text = ""
        var styles: [TextStyle] = []

        func traverse(_ node: any Markup) {
            switch node {
            case let t as Markdown.Text:
                text += t.string
            case let strong as Strong:
                let strongText = extractPlainText(from: strong)
                text += strongText
                styles.append(.bold)
            case let emphasis as Emphasis:
                let emText = extractPlainText(from: emphasis)
                text += emText
                styles.append(.italic)
            case let code as InlineCode:
                text += code.code
                styles.append(.code)
            case let link as Markdown.Link:
                let linkText = extractPlainText(from: link)
                text += linkText
                if let dest = link.destination {
                    styles.append(.link(url: dest))
                }
            case let strikethrough as Strikethrough:
                let stText = extractPlainText(from: strikethrough)
                text += stText
                styles.append(.strikethrough)
            case is SoftBreak, is LineBreak:
                text += " "
            default:
                for child in node.children {
                    traverse(child)
                }
            }
        }

        for child in markup.children {
            traverse(child)
        }

        return AttributedText(text, styles: styles)
    }

    private func processUnorderedList(_ list: UnorderedList, depth: Int = 0) -> [ListItem] {
        var result: [ListItem] = []

        for item in list.listItems {
            let text = extractPlainText(from: item).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            var children: [ListItem] = []

            // Process nested lists
            for child in item.children {
                if let nestedList = child as? UnorderedList {
                    children = processUnorderedList(nestedList, depth: depth + 1)
                } else if let nestedList = child as? OrderedList {
                    children = processOrderedList(nestedList, depth: depth + 1)
                }
            }

            result.append(ListItem(
                content: AttributedText(text),
                children: children,
                depth: depth
            ))
        }

        return result
    }

    private func processOrderedList(_ list: OrderedList, depth: Int = 0) -> [ListItem] {
        var result: [ListItem] = []

        for item in list.listItems {
            let text = extractPlainText(from: item).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            var children: [ListItem] = []

            // Process nested lists
            for child in item.children {
                if let nestedList = child as? UnorderedList {
                    children = processUnorderedList(nestedList, depth: depth + 1)
                } else if let nestedList = child as? OrderedList {
                    children = processOrderedList(nestedList, depth: depth + 1)
                }
            }

            result.append(ListItem(
                content: AttributedText(text),
                children: children,
                depth: depth
            ))
        }

        return result
    }

    private func processTable(_ table: Markdown.Table) -> Table {
        var headers: [String] = []
        var rows: [[String]] = []
        var alignments: [Table.TableAlignment] = []

        // Process header
        let head = table.head
        for cell in head.cells {
            headers.append(extractPlainText(from: cell))
        }

        // Process column alignments
        let columnCount = headers.count
        for i in 0..<columnCount {
            if i < table.columnAlignments.count {
                let alignment = table.columnAlignments[i]
                switch alignment {
                case .some(.left): alignments.append(.left)
                case .some(.center): alignments.append(.center)
                case .some(.right): alignments.append(.right)
                case .none: alignments.append(.left)
                }
            } else {
                alignments.append(.left)
            }
        }

        // Process rows
        for row in table.body.rows {
            var rowData: [String] = []
            for cell in row.cells {
                rowData.append(extractPlainText(from: cell))
            }
            rows.append(rowData)
        }

        return Table(headers: headers, rows: rows, alignments: alignments)
    }

    private func extractPlainText(from markup: any Markup) -> String {
        var result = ""

        func traverse(_ node: any Markup) {
            if let text = node as? Markdown.Text {
                result += text.string
            } else if node is SoftBreak || node is LineBreak {
                result += " "
            } else {
                for child in node.children {
                    traverse(child)
                }
            }
        }

        traverse(markup)
        return result
    }

    private func isChecklistItem(_ item: ListItem) -> Bool {
        let text = item.content.text
        return text.hasPrefix("[ ]") || text.hasPrefix("[x]") || text.hasPrefix("[X]")
    }

    private func parseChecklistText(_ text: String) -> (isChecked: Bool, content: String) {
        if text.hasPrefix("[x]") || text.hasPrefix("[X]") {
            return (true, String(text.dropFirst(3)).trimmingCharacters(in: CharacterSet.whitespaces))
        } else if text.hasPrefix("[ ]") {
            return (false, String(text.dropFirst(3)).trimmingCharacters(in: CharacterSet.whitespaces))
        }
        return (false, text)
    }
}
