import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("Tag Model Tests")
struct TagTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Create and fetch a tag")
    func createAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = TestFixtures.makeTag(name: "urgent", color: "FF0000")
        context.insert(tag)
        try context.save()

        let descriptor = FetchDescriptor<Planner.Tag>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results.first?.name == "urgent")
        #expect(results.first?.color == "FF0000")
    }

    @Test("Tag has meetings relationship")
    func meetingsRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = TestFixtures.makeTag(name: "project-x")
        context.insert(tag)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        meeting.tags.append(tag)
        try context.save()

        #expect(tag.meetingRecords.count == 1)
    }

    @Test("Tag has notes relationship")
    func notesRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let tag = TestFixtures.makeTag(name: "ideas")
        context.insert(tag)

        let note = TestFixtures.makeNote()
        context.insert(note)

        note.tags.append(tag)
        try context.save()

        #expect(tag.notes.count == 1)
    }
}
