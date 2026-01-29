import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("MeetingRecord Model Tests")
struct MeetingRecordTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Create and fetch a meeting record")
    func createAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting(title: "Design Review")
        context.insert(meeting)
        try context.save()

        let descriptor = FetchDescriptor<MeetingRecord>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results.first?.title == "Design Review")
    }

    @Test("Meeting cascade deletes notes")
    func cascadeDeleteNotes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let note = TestFixtures.makeNote(meetingRecord: meeting)
        context.insert(note)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 1)

        context.delete(meeting)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 0)
    }

    @Test("Meeting cascade deletes embeddings")
    func cascadeDeleteEmbeddings() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let embedding = EmbeddingRecord(
            chunkText: "test chunk",
            vector: Array(repeating: 0.1, count: 512),
            sourceType: "meeting",
            meetingRecord: meeting
        )
        context.insert(embedding)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<EmbeddingRecord>()) == 1)

        context.delete(meeting)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<EmbeddingRecord>()) == 0)
    }

    @Test("Meeting has attendees relationship")
    func attendeesRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let person = TestFixtures.makePerson(email: "alice@example.com", name: "Alice")
        context.insert(person)

        meeting.attendees.append(person)
        try context.save()

        #expect(meeting.attendees.count == 1)
        #expect(meeting.attendees.first?.name == "Alice")
    }

    @Test("Meeting has tags relationship")
    func tagsRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let tag = TestFixtures.makeTag(name: "important")
        context.insert(tag)

        meeting.tags.append(tag)
        try context.save()

        #expect(meeting.tags.count == 1)
        #expect(meeting.tags.first?.name == "important")
    }
}
