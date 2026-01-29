import Foundation

struct QueryResponse: Identifiable {
    let id = UUID()
    let answer: String
    let sources: [SearchResult]
    let confidence: Double
}
