import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("Note Model Tests")
struct NoteTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Create and fetch a note")
    func createAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = TestFixtures.makeNote(title: "My Note", plainText: "Some content")
        context.insert(note)
        try context.save()

        let descriptor = FetchDescriptor<Note>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results.first?.title == "My Note")
        #expect(results.first?.plainText == "Some content")
    }

    @Test("Note cascade deletes embeddings")
    func cascadeDeleteEmbeddings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = TestFixtures.makeNote()
        context.insert(note)

        let embedding = EmbeddingRecord(
            chunkText: "test chunk",
            vector: Array(repeating: 0.1, count: 512),
            sourceType: "note",
            note: note
        )
        context.insert(embedding)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<EmbeddingRecord>()) == 1)

        context.delete(note)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<EmbeddingRecord>()) == 0)
    }

    @Test("Note links to meeting record")
    func meetingRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let note = TestFixtures.makeNote(meetingRecord: meeting)
        context.insert(note)
        try context.save()

        #expect(note.meetingRecord?.title == meeting.title)
        #expect(meeting.notes.count == 1)
    }
}
