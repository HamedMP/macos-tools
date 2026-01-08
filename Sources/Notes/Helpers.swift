import Foundation

func printHeader(_ title: String) {
    print("\(title)")
    print(String(repeating: "-", count: 50))
}

func printNote(_ note: Note) {
    print("  \(note.title) [\(note.folder)]")
    if !note.snippet.isEmpty {
        let truncatedSnippet = String(note.snippet.prefix(60))
        print("    \(truncatedSnippet)...")
    }
}

func sanitizeFilename(_ name: String) -> String {
    let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
    var sanitized = name.components(separatedBy: invalidChars).joined(separator: "-")
    sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    if sanitized.isEmpty {
        sanitized = "Untitled"
    }
    return String(sanitized.prefix(100))
}

func htmlToText(_ html: String) -> String {
    var text = html

    // Replace common HTML tags
    text = text.replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</li>", with: "\n", options: .caseInsensitive)

    // Convert lists
    text = text.replacingOccurrences(of: "<li>", with: "- ", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "<ul>", with: "", options: .caseInsensitive)
    text = text.replacingOccurrences(of: "</ul>", with: "\n", options: .caseInsensitive)

    // Strip remaining HTML tags
    while let tagStart = text.range(of: "<"),
          let tagEnd = text.range(of: ">", range: tagStart.upperBound..<text.endIndex) {
        text.removeSubrange(tagStart.lowerBound...tagEnd.lowerBound)
    }

    // Decode common HTML entities
    text = text.replacingOccurrences(of: "&nbsp;", with: " ")
    text = text.replacingOccurrences(of: "&amp;", with: "&")
    text = text.replacingOccurrences(of: "&lt;", with: "<")
    text = text.replacingOccurrences(of: "&gt;", with: ">")
    text = text.replacingOccurrences(of: "&quot;", with: "\"")
    text = text.replacingOccurrences(of: "&#39;", with: "'")

    // Clean up whitespace
    text = text.replacingOccurrences(of: "\n\n\n+", with: "\n\n", options: .regularExpression)
    text = text.trimmingCharacters(in: .whitespacesAndNewlines)

    return text
}
