import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("Person Model Tests")
struct PersonTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Create and fetch a person")
    func createAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let person = TestFixtures.makePerson(email: "jane@example.com", name: "Jane Smith")
        context.insert(person)
        try context.save()

        let descriptor = FetchDescriptor<Person>()
        let results = try context.fetch(descriptor)

        #expect(results.count == 1)
        #expect(results.first?.email == "jane@example.com")
        #expect(results.first?.name == "Jane Smith")
    }

    @Test("Person tracks meeting count")
    func meetingCount() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let person = TestFixtures.makePerson(meetingCount: 10)
        context.insert(person)
        try context.save()

        #expect(person.meetingCount == 10)

        person.meetingCount += 1
        try context.save()

        #expect(person.meetingCount == 11)
    }

    @Test("Person has meetings relationship")
    func meetingsRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let person = TestFixtures.makePerson()
        context.insert(person)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        meeting.attendees.append(person)
        try context.save()

        #expect(person.meetings.count == 1)
    }
}
