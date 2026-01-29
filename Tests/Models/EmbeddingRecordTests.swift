import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("EmbeddingRecord Model Tests")
struct EmbeddingRecordTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Vector data roundtrip preserves values")
    func vectorRoundtrip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let originalVector = VectorTestHelpers.randomNormalizedVector()
        let record = EmbeddingRecord(
            chunkText: "Test chunk",
            vector: originalVector,
            sourceType: "meeting"
        )
        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        let fetched = try context.fetch(descriptor).first!

        let retrievedVector = fetched.vector
        #expect(retrievedVector.count == originalVector.count)

        for (a, b) in zip(originalVector, retrievedVector) {
            #expect(abs(a - b) < 1e-10)
        }
    }

    @Test("Embedding links to meeting record")
    func meetingRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let record = EmbeddingRecord(
            chunkText: "Meeting chunk",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting",
            meetingRecord: meeting
        )
        context.insert(record)
        try context.save()

        #expect(record.meetingRecord?.title == meeting.title)
        #expect(meeting.embeddings.count == 1)
    }

    @Test("Embedding links to note")
    func noteRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = TestFixtures.makeNote()
        context.insert(note)

        let record = EmbeddingRecord(
            chunkText: "Note chunk",
            vector: VectorTestHelpers.unitVector,
            sourceType: "note",
            note: note
        )
        context.insert(record)
        try context.save()

        #expect(record.note?.title == note.title)
        #expect(note.embeddings.count == 1)
    }
}
