import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("RAG Service Tests")
struct RAGServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Cosine similarity of identical vectors is 1.0")
    func cosineSimilarityIdentical() {
        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let a = VectorTestHelpers.unitVector
        let b = VectorTestHelpers.identicalVector
        let similarity = ragService.cosineSimilarity(a, b)

        #expect(abs(similarity - 1.0) < 1e-10)
    }

    @Test("Cosine similarity of orthogonal vectors is 0.0")
    func cosineSimilarityOrthogonal() {
        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let a = VectorTestHelpers.unitVector
        let b = VectorTestHelpers.orthogonalVector
        let similarity = ragService.cosineSimilarity(a, b)

        #expect(abs(similarity) < 1e-10)
    }

    @Test("Cosine similarity of opposite vectors is -1.0")
    func cosineSimilarityOpposite() {
        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let a = VectorTestHelpers.unitVector
        let b = VectorTestHelpers.oppositeVector
        let similarity = ragService.cosineSimilarity(a, b)

        #expect(abs(similarity + 1.0) < 1e-10)
    }

    @Test("Cosine similarity of empty vectors is 0.0")
    func cosineSimilarityEmpty() {
        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let similarity = ragService.cosineSimilarity([], [])
        #expect(similarity == 0.0)
    }

    @Test("Indexing a meeting creates embedding records")
    func indexMeeting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let meeting = TestFixtures.makeMeeting(
            title: "Sprint Planning",
            location: "Room 101",
            purpose: "Plan next sprint"
        )
        context.insert(meeting)

        ragService.indexMeetingRecord(meeting, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        #expect(embeddings.count > 0)
        #expect(embeddingService.generateVectorCallCount > 0)
    }

    @Test("Indexing a note creates embedding records")
    func indexNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let note = TestFixtures.makeNote(
            plainText: "This is a longer note with enough content to be indexed properly by the system."
        )
        context.insert(note)

        ragService.indexNote(note, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        #expect(embeddings.count > 0)
    }

    @Test("Search returns results sorted by score")
    func searchReturnsSorted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create embeddings with different vectors
        let high = EmbeddingRecord(
            chunkText: "High relevance",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting"
        )
        let medium = EmbeddingRecord(
            chunkText: "Medium relevance",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "meeting"
        )
        context.insert(high)
        context.insert(medium)
        try context.save()

        let results = ragService.search(query: "test", topK: 10, context: context)

        #expect(results.count >= 1)
        if results.count >= 2 {
            #expect(results[0].score >= results[1].score)
        }
    }
}
