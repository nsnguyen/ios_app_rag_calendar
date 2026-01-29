import Foundation

extension NSAttributedString {
    /// Extracts plain text suitable for RAG indexing.
    /// Strips formatting and normalizes whitespace.
    var extractedPlainText: String {
        let text = string
        // Normalize whitespace: collapse multiple spaces/newlines
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
