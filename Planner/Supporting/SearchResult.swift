import Foundation

struct SearchResult: Identifiable {
    let id = UUID()
    let embeddingRecord: EmbeddingRecord
    let score: Double

    var sourceType: String {
        embeddingRecord.sourceType
    }

    var chunkText: String {
        embeddingRecord.chunkText
    }
}
