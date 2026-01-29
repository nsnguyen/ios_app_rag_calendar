import Testing
import CoreSpotlight
import Foundation
import SwiftData
@testable import Planner

@Suite("Spotlight Service Tests")
struct SpotlightServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Index meeting does not throw")
    func indexMeeting() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting(title: "Indexed Meeting")
        context.insert(meeting)
        try context.save()

        let service = SpotlightService()
        // Should not crash
        service.indexMeeting(meeting)
    }

    @Test("Index note does not throw")
    func indexNote() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let note = TestFixtures.makeNote(title: "Indexed Note")
        context.insert(note)
        try context.save()

        let service = SpotlightService()
        // Should not crash
        service.indexNote(note)
    }

    @Test("Remove from index does not throw")
    func removeFromIndex() {
        let service = SpotlightService()
        // Should not crash
        service.removeFromIndex(identifier: "meeting:test-id")
    }
}
