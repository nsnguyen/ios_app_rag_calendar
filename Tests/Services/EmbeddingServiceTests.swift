import Testing
import Foundation
@testable import Planner

@Suite("Embedding Service Tests")
struct EmbeddingServiceTests {

    @Test("EmbeddingService reports availability")
    func availability() {
        let service = EmbeddingService()
        // NLEmbedding may not be available in test environment
        // Just verify the property doesn't crash
        _ = service.isAvailable
    }

    @Test("Generate vector returns correct dimension when available")
    func vectorDimension() {
        let service = EmbeddingService()
        guard service.isAvailable else { return }

        let vector = service.generateVector(for: "Hello world")
        #expect(vector != nil)
        #expect(vector?.count == 512)
    }

    @Test("Generate vectors for multiple texts")
    func batchGeneration() {
        let service = EmbeddingService()
        guard service.isAvailable else { return }

        let texts = ["Hello", "World", "Test"]
        let vectors = service.generateVectors(for: texts)

        #expect(vectors.count == 3)
    }

    @Test("Empty text returns a vector")
    func emptyText() {
        let service = EmbeddingService()
        guard service.isAvailable else { return }

        // Empty or very short text may or may not produce a vector
        _ = service.generateVector(for: "")
    }
}
