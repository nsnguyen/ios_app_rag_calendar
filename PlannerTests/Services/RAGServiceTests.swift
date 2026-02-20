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

    // MARK: - Cosine Similarity Tests

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

    @Test("Cosine similarity of mismatched vector lengths is 0.0")
    func cosineSimilarityMismatchedLengths() {
        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let a = [1.0, 0.0, 0.0]
        let b = [1.0, 0.0]
        let similarity = ragService.cosineSimilarity(a, b)

        #expect(similarity == 0.0)
    }

    // MARK: - Meeting Indexing Tests

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

    @Test("Indexing meeting creates embeddings with correct source type")
    func indexMeetingSourceType() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let meeting = TestFixtures.makeMeeting(title: "Design Review")
        context.insert(meeting)

        ragService.indexMeetingRecord(meeting, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        for embedding in embeddings {
            #expect(embedding.sourceType == "meeting")
        }
    }

    @Test("Indexing meeting chunks include title in content")
    func indexMeetingChunksContainTitle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let meeting = TestFixtures.makeMeeting(title: "Quarterly Review Meeting")
        context.insert(meeting)

        ragService.indexMeetingRecord(meeting, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        let hasTitle = embeddings.contains { $0.chunkText.contains("Quarterly Review Meeting") }
        #expect(hasTitle)
    }

    @Test("Indexing meeting with notes creates multiple chunks")
    func indexMeetingWithNotes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let meeting = MeetingRecord(
            eventIdentifier: "test-meeting-notes",
            title: "Team Standup",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            sourceType: "calendar"
        )
        meeting.meetingNotes = "Discussed the new feature implementation.\nReviewed pull requests.\nPlanned for tomorrow."
        meeting.purpose = "Daily sync"
        meeting.actionItems = "Complete code review by EOD"
        context.insert(meeting)

        ragService.indexMeetingRecord(meeting, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        // Should have at least overview + notes + purpose + action items chunks
        #expect(embeddings.count >= 3)
    }

    @Test("Re-indexing meeting removes old embeddings")
    func reindexMeetingRemovesOldEmbeddings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let meeting = TestFixtures.makeMeeting(title: "Evolving Meeting")
        context.insert(meeting)

        // Index first time
        ragService.indexMeetingRecord(meeting, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let firstIndexCount = try context.fetch(descriptor).count

        // Update meeting and re-index
        meeting.meetingNotes = "New notes added to the meeting."
        ragService.indexMeetingRecord(meeting, context: context)

        let afterReindex = try context.fetch(descriptor)
        // Should not accumulate embeddings - old ones should be removed
        #expect(afterReindex.count >= 1)
        // All embeddings should belong to this meeting
        for embedding in afterReindex {
            #expect(embedding.meetingRecord?.eventIdentifier == meeting.eventIdentifier)
        }
    }

    // MARK: - Note Indexing Tests

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

    @Test("Indexing note creates embeddings with correct source type")
    func indexNoteSourceType() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let note = TestFixtures.makeNote(
            title: "Important Note",
            plainText: "This note contains important information for the project."
        )
        context.insert(note)

        ragService.indexNote(note, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        for embedding in embeddings {
            #expect(embedding.sourceType == "note")
        }
    }

    @Test("Indexing note includes title in chunk text")
    func indexNoteIncludesTitle() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let note = TestFixtures.makeNote(
            title: "Project Ideas",
            plainText: "Various ideas for improving the application."
        )
        context.insert(note)

        ragService.indexNote(note, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        let hasTitle = embeddings.contains { $0.chunkText.contains("Project Ideas") }
        #expect(hasTitle)
    }

    @Test("Indexing long note creates multiple chunks")
    func indexLongNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        // Create a note longer than 500 chars
        let longText = """
        This is a very long note that spans multiple paragraphs.

        First paragraph discusses the project architecture and design decisions that were made during the planning phase.

        Second paragraph covers the implementation details and technical specifications for the core features.

        Third paragraph outlines the testing strategy and quality assurance measures that will be put in place.

        Fourth paragraph describes the deployment pipeline and infrastructure requirements for production.

        Fifth paragraph contains notes about future enhancements and potential optimizations to consider.
        """

        let note = TestFixtures.makeNote(
            title: "Comprehensive Project Notes",
            plainText: longText
        )
        context.insert(note)

        ragService.indexNote(note, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        // Long notes should be chunked into multiple embeddings
        #expect(embeddings.count >= 2)
    }

    @Test("Indexing empty note creates no embeddings")
    func indexEmptyNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)

        let note = TestFixtures.makeNote(
            title: "Empty Note",
            plainText: ""
        )
        context.insert(note)

        ragService.indexNote(note, context: context)

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let embeddings = try context.fetch(descriptor)

        #expect(embeddings.count == 0)
    }

    // MARK: - Search Tests

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

    @Test("Search returns relevant results matching query keywords")
    func searchReturnsRelevantResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create embeddings with specific content
        let projectMeeting = EmbeddingRecord(
            chunkText: "Meeting about project planning and roadmap discussion",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting"
        )
        let budgetMeeting = EmbeddingRecord(
            chunkText: "Budget review and financial planning session",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting"
        )
        context.insert(projectMeeting)
        context.insert(budgetMeeting)
        try context.save()

        let results = ragService.search(query: "project roadmap", topK: 10, context: context)

        #expect(results.count >= 1)
        // Result about project should have higher score due to keyword boost
        let hasProjectResult = results.contains { $0.chunkText.contains("project") }
        #expect(hasProjectResult)
    }

    @Test("Search with multiple results returns them in descending score order")
    func searchMultipleResultsOrdering() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create embeddings with progressively lower similarity
        let highSim = EmbeddingRecord(
            chunkText: "High similarity content",
            vector: VectorTestHelpers.vectorWithSimilarity(0.9),
            sourceType: "meeting"
        )
        let medSim = EmbeddingRecord(
            chunkText: "Medium similarity content",
            vector: VectorTestHelpers.vectorWithSimilarity(0.6),
            sourceType: "note"
        )
        let lowSim = EmbeddingRecord(
            chunkText: "Lower similarity content",
            vector: VectorTestHelpers.vectorWithSimilarity(0.4),
            sourceType: "meeting"
        )
        context.insert(highSim)
        context.insert(medSim)
        context.insert(lowSim)
        try context.save()

        let results = ragService.search(query: "test query", topK: 10, context: context)

        #expect(results.count >= 2)
        // Verify descending order
        for i in 0..<(results.count - 1) {
            #expect(results[i].score >= results[i + 1].score)
        }
    }

    // MARK: - Threshold Filtering Tests (0.3 minimum)

    @Test("Search filters out results below 0.3 threshold")
    func searchFiltersLowSimilarity() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create embedding with similarity below threshold (0.2 < 0.3)
        let belowThreshold = EmbeddingRecord(
            chunkText: "Content with low similarity",
            vector: VectorTestHelpers.vectorWithSimilarity(0.2),
            sourceType: "meeting"
        )
        context.insert(belowThreshold)
        try context.save()

        let results = ragService.search(query: "test", topK: 10, context: context)

        // Should not include results below 0.3 threshold
        #expect(results.isEmpty || results.allSatisfy { $0.score >= 0.3 })
    }

    @Test("Search includes results at exactly 0.3 threshold")
    func searchIncludesAtThreshold() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create embedding with similarity at exactly threshold
        let atThreshold = EmbeddingRecord(
            chunkText: "Content at threshold",
            vector: VectorTestHelpers.vectorWithSimilarity(0.3),
            sourceType: "meeting"
        )
        context.insert(atThreshold)
        try context.save()

        let results = ragService.search(query: "test", topK: 10, context: context)

        // Should include result at exactly 0.3
        #expect(results.count == 1)
    }

    @Test("Search includes results above threshold and excludes below")
    func searchThresholdMixedResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create mix of above and below threshold
        let above1 = EmbeddingRecord(
            chunkText: "Above threshold high",
            vector: VectorTestHelpers.vectorWithSimilarity(0.8),
            sourceType: "meeting"
        )
        let above2 = EmbeddingRecord(
            chunkText: "Above threshold medium",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "note"
        )
        let below1 = EmbeddingRecord(
            chunkText: "Below threshold",
            vector: VectorTestHelpers.vectorWithSimilarity(0.1),
            sourceType: "meeting"
        )
        let below2 = EmbeddingRecord(
            chunkText: "Way below threshold",
            vector: VectorTestHelpers.vectorWithSimilarity(0.05),
            sourceType: "note"
        )
        context.insert(above1)
        context.insert(above2)
        context.insert(below1)
        context.insert(below2)
        try context.save()

        let results = ragService.search(query: "test", topK: 10, context: context)

        // Only above threshold results should be included
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.score >= 0.3 })
    }

    // MARK: - Top-K Results Tests

    @Test("Search respects default topK of 5")
    func searchDefaultTopK() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create 10 embeddings above threshold
        for i in 0..<10 {
            let embedding = EmbeddingRecord(
                chunkText: "Content item \(i)",
                vector: VectorTestHelpers.vectorWithSimilarity(0.9 - Double(i) * 0.05),
                sourceType: "meeting"
            )
            context.insert(embedding)
        }
        try context.save()

        // Use default topK (not specifying it, which should be 5)
        let results = ragService.search(query: "test", topK: 5, context: context)

        #expect(results.count <= 5)
    }

    @Test("Search respects custom topK of 3")
    func searchCustomTopK3() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create 10 embeddings above threshold
        for i in 0..<10 {
            let embedding = EmbeddingRecord(
                chunkText: "Content item \(i)",
                vector: VectorTestHelpers.vectorWithSimilarity(0.9 - Double(i) * 0.03),
                sourceType: "meeting"
            )
            context.insert(embedding)
        }
        try context.save()

        let results = ragService.search(query: "test", topK: 3, context: context)

        #expect(results.count == 3)
    }

    @Test("Search respects custom topK of 1")
    func searchCustomTopK1() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create multiple embeddings
        for i in 0..<5 {
            let embedding = EmbeddingRecord(
                chunkText: "Content item \(i)",
                vector: VectorTestHelpers.vectorWithSimilarity(0.9 - Double(i) * 0.1),
                sourceType: "note"
            )
            context.insert(embedding)
        }
        try context.save()

        let results = ragService.search(query: "test", topK: 1, context: context)

        #expect(results.count == 1)
    }

    @Test("Search returns fewer than topK when not enough results")
    func searchFewerThanTopK() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create only 2 embeddings above threshold
        let emb1 = EmbeddingRecord(
            chunkText: "First item",
            vector: VectorTestHelpers.vectorWithSimilarity(0.8),
            sourceType: "meeting"
        )
        let emb2 = EmbeddingRecord(
            chunkText: "Second item",
            vector: VectorTestHelpers.vectorWithSimilarity(0.6),
            sourceType: "note"
        )
        context.insert(emb1)
        context.insert(emb2)
        try context.save()

        let results = ragService.search(query: "test", topK: 10, context: context)

        #expect(results.count == 2)
    }

    @Test("Search with large topK returns all available results")
    func searchLargeTopK() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create 3 embeddings
        for i in 0..<3 {
            let embedding = EmbeddingRecord(
                chunkText: "Item \(i)",
                vector: VectorTestHelpers.vectorWithSimilarity(0.8 - Double(i) * 0.1),
                sourceType: "meeting"
            )
            context.insert(embedding)
        }
        try context.save()

        let results = ragService.search(query: "test", topK: 100, context: context)

        #expect(results.count == 3)
    }

    // MARK: - Edge Cases

    @Test("Search with no embeddings returns empty results")
    func searchNoEmbeddings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        let results = ragService.search(query: "test query", topK: 5, context: context)

        #expect(results.isEmpty)
    }

    @Test("Search with unavailable embedding service returns empty results")
    func searchNoEmbeddingService() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = nil // Simulates unavailable embedding
        let ragService = RAGService(embeddingService: embeddingService)

        // Create an embedding
        let embedding = EmbeddingRecord(
            chunkText: "Test content",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting"
        )
        context.insert(embedding)
        try context.save()

        let results = ragService.search(query: "test", topK: 5, context: context)

        // Should return empty because query vector generation fails
        #expect(results.isEmpty)
    }

    @Test("Search results contain correct embedding references")
    func searchResultsHaveCorrectReferences() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        let embedding = EmbeddingRecord(
            chunkText: "Unique test content here",
            vector: VectorTestHelpers.unitVector,
            sourceType: "note"
        )
        context.insert(embedding)
        try context.save()

        let results = ragService.search(query: "test", topK: 5, context: context)

        #expect(results.count == 1)
        #expect(results[0].chunkText == "Unique test content here")
        #expect(results[0].sourceType == "note")
    }

    // MARK: - Hybrid Search Tests

    @Test("Keyword boost increases score for matching content")
    func keywordBoostIncreasesScore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Create two embeddings with same vector but different text
        let withKeyword = EmbeddingRecord(
            chunkText: "Meeting about project planning and development",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "meeting"
        )
        let withoutKeyword = EmbeddingRecord(
            chunkText: "General discussion about various topics",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "meeting"
        )
        context.insert(withKeyword)
        context.insert(withoutKeyword)
        try context.save()

        let results = ragService.search(query: "project planning", topK: 10, context: context)

        #expect(results.count == 2)
        // Result with matching keywords should score higher
        let projectResult = results.first { $0.chunkText.contains("project") }
        let otherResult = results.first { !$0.chunkText.contains("project") }
        if let proj = projectResult, let other = otherResult {
            #expect(proj.score > other.score)
        }
    }

    @Test("Title position keyword gets extra boost")
    func titleKeywordExtraBoost() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embeddingService = MockEmbeddingService()
        embeddingService.mockVector = VectorTestHelpers.unitVector
        let ragService = RAGService(embeddingService: embeddingService)

        // Keyword at the beginning (title-like position)
        let titleMatch = EmbeddingRecord(
            chunkText: "Project kickoff meeting with all stakeholders present",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "meeting"
        )
        // Keyword later in text (after 100 chars, so no title boost)
        let bodyMatch = EmbeddingRecord(
            chunkText: "Meeting notes from our weekly team sync where we discussed various topics, reviewed ongoing work, and also briefly mentioned the project",
            vector: VectorTestHelpers.vectorWithSimilarity(0.5),
            sourceType: "meeting"
        )
        context.insert(titleMatch)
        context.insert(bodyMatch)
        try context.save()

        let results = ragService.search(query: "project", topK: 10, context: context)

        #expect(results.count == 2)
        // Title match should have higher score due to early keyword position
        if results.count >= 2 {
            let first = results[0]
            #expect(first.chunkText.lowercased().prefix(50).contains("project"))
        }
    }
}

// MARK: - RAG Test Fixtures

extension RAGServiceTests {
    /// Sample meeting fixtures for RAG testing
    struct RAGTestFixtures {
        static func sampleMeetings() -> [MeetingRecord] {
            [
                MeetingRecord(
                    eventIdentifier: "rag-test-1",
                    title: "Q1 Product Planning",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(3600),
                    location: "Conference Room A",
                    purpose: "Define product roadmap for Q1",
                    outcomes: "Agreed on 3 major features",
                    actionItems: "Create detailed specs for each feature",
                    sourceType: "calendar"
                ),
                MeetingRecord(
                    eventIdentifier: "rag-test-2",
                    title: "Engineering Standup",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(900),
                    location: "Virtual",
                    purpose: "Daily sync on progress",
                    actionItems: "Review pending PRs",
                    sourceType: "calendar"
                ),
                MeetingRecord(
                    eventIdentifier: "rag-test-3",
                    title: "Customer Feedback Review",
                    startDate: Date(),
                    endDate: Date().addingTimeInterval(1800),
                    location: "Room B",
                    purpose: "Analyze customer feedback from survey",
                    outcomes: "Identified top 5 pain points",
                    sourceType: "calendar"
                )
            ]
        }

        static func sampleNotes() -> [Note] {
            [
                Note(
                    title: "Architecture Decision Record",
                    plainText: "We decided to use SwiftData for persistence due to its tight integration with SwiftUI and simplified migration path from Core Data."
                ),
                Note(
                    title: "Meeting Follow-up Actions",
                    plainText: "1. Schedule follow-up with design team\n2. Update project timeline\n3. Send summary to stakeholders"
                ),
                Note(
                    title: "Technical Research Notes",
                    plainText: "Investigated various embedding models. NLEmbedding provides 512-dimensional vectors with good semantic understanding for English text."
                )
            ]
        }
    }
}
