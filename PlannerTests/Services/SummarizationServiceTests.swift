import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("Summarization Service Tests")
struct SummarizationServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Generate meeting summary returns non-nil")
    func meetingSummary() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting(title: "Team Standup")
        context.insert(meeting)

        let service = SummarizationService()
        let summary = await service.generateMeetingSummary(for: meeting)

        #expect(summary != nil)
        #expect(summary?.contains("Team Standup") == true)
    }

    @Test("Extract action items from meeting notes")
    func extractActionItems() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        meeting.meetingNotes = "- [ ] Follow up with design team\nSome regular text\nTODO: Update docs"
        context.insert(meeting)

        let service = SummarizationService()
        let items = await service.extractActionItems(from: meeting)

        #expect(items.count == 2)
    }

    @Test("Generate meeting brief with previous meetings")
    func meetingBrief() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        let person = TestFixtures.makePerson()
        context.insert(meeting)
        context.insert(person)
        meeting.attendees.append(person)

        let previousMeeting = TestFixtures.makeMeeting(
            eventIdentifier: "prev-event",
            title: "Previous Meeting",
            startDate: Date().addingTimeInterval(-86400)
        )
        context.insert(previousMeeting)
        try context.save()

        let service = SummarizationService()
        let brief = await service.generateMeetingBrief(for: meeting, previousMeetings: [previousMeeting])

        #expect(brief != nil)
        #expect(brief?.meetingTitle == meeting.title)
    }

    @Test("Generate inspiration phrase for each tone")
    func inspirationPhrases() async {
        let service = SummarizationService()

        for tone in InspirationPhrase.Tone.allCases {
            let phrase = await service.generateInspirationPhrase(
                meetingCount: 3,
                noteCount: 5,
                tone: tone
            )
            #expect(phrase != nil)
            #expect(!phrase!.isEmpty)
        }
    }
}
