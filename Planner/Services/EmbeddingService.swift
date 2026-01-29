import Foundation
import NaturalLanguage

protocol EmbeddingServiceProtocol: Sendable {
    var isAvailable: Bool { get }
    func generateVector(for text: String) -> [Double]?
    func generateVectors(for texts: [String]) -> [[Double]?]
}

final class EmbeddingService: EmbeddingServiceProtocol, @unchecked Sendable {
    private let embedding: NLEmbedding?

    init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }

    var isAvailable: Bool {
        embedding != nil
    }

    func generateVector(for text: String) -> [Double]? {
        guard let embedding else { return nil }
        return embedding.vector(for: text)
    }

    func generateVectors(for texts: [String]) -> [[Double]?] {
        texts.map { generateVector(for: $0) }
    }
}
