import Foundation
@testable import Planner

final class MockEmbeddingService: EmbeddingServiceProtocol, @unchecked Sendable {
    var mockIsAvailable = true
    var mockVector: [Double]? = Array(repeating: 0.1, count: 512)
    var generateVectorCallCount = 0
    var lastGeneratedText: String?

    var isAvailable: Bool {
        mockIsAvailable
    }

    func generateVector(for text: String) -> [Double]? {
        generateVectorCallCount += 1
        lastGeneratedText = text
        return mockVector
    }

    func generateVectors(for texts: [String]) -> [[Double]?] {
        texts.map { generateVector(for: $0) }
    }
}
