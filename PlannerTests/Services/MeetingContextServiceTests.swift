import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("MeetingContext Service Tests")
struct MeetingContextServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Sync calendar events creates meeting records")
    func syncCreates() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockCalendar = MockCalendarService()
        mockCalendar.mockEvents = [
            TestFixtures.makeCalendarEventData(title: "Meeting 1"),
            TestFixtures.makeCalendarEventData(title: "Meeting 2"),
        ]

        let mockRAG = MockRAGService()
        let service = MeetingContextService(
            calendarService: mockCalendar,
            ragService: mockRAG,
            embeddingService: MockEmbeddingService(),
            summarizationService: MockSummarizationService()
        )

        await service.syncCalendarEvents(context: context)

        let descriptor = FetchDescriptor<MeetingRecord>()
        let meetings = try context.fetch(descriptor)

        #expect(meetings.count == 2)
        #expect(mockCalendar.fetchEventsCallCount == 1)
    }

    @Test("Sync upserts existing meetings")
    func syncUpserts() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let eventData = TestFixtures.makeCalendarEventData(
            eventIdentifier: "same-id",
            title: "Original Title"
        )

        let mockCalendar = MockCalendarService()
        mockCalendar.mockEvents = [eventData]

        let service = MeetingContextService(
            calendarService: mockCalendar,
            ragService: MockRAGService(),
            embeddingService: MockEmbeddingService(),
            summarizationService: MockSummarizationService()
        )

        await service.syncCalendarEvents(context: context)

        // Sync again with updated title
        let updatedEvent = CalendarEventData(
            eventIdentifier: "same-id",
            title: "Updated Title",
            startDate: eventData.startDate,
            endDate: eventData.endDate,
            location: eventData.location,
            isAllDay: eventData.isAllDay,
            attendeeEmails: eventData.attendeeEmails
        )
        mockCalendar.mockEvents = [updatedEvent]
        await service.syncCalendarEvents(context: context)

        let descriptor = FetchDescriptor<MeetingRecord>()
        let meetings = try context.fetch(descriptor)

        #expect(meetings.count == 1)
        #expect(meetings.first?.title == "Updated Title")
    }

    @Test("Generate timeline for a date returns entries")
    func generateTimeline() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let today = Date()
        let meeting = TestFixtures.makeMeeting(startDate: today, endDate: today.addingTimeInterval(3600))
        context.insert(meeting)
        try context.save()

        let service = MeetingContextService(
            calendarService: MockCalendarService(),
            ragService: MockRAGService(),
            embeddingService: MockEmbeddingService(),
            summarizationService: MockSummarizationService()
        )

        let entries = service.generateTimeline(for: today, context: context)
        #expect(entries.count == 1)
        #expect(entries.first?.title == meeting.title)
    }

    @Test("Answer question uses RAG service")
    func answerQuestion() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let embedding = EmbeddingRecord(
            chunkText: "Sprint planning with team",
            vector: VectorTestHelpers.unitVector,
            sourceType: "meeting"
        )
        context.insert(embedding)
        try context.save()

        let mockRAG = MockRAGService()
        mockRAG.mockSearchResults = [
            SearchResult(embeddingRecord: embedding, score: 0.9)
        ]

        let service = MeetingContextService(
            calendarService: MockCalendarService(),
            ragService: mockRAG,
            embeddingService: MockEmbeddingService(),
            summarizationService: MockSummarizationService()
        )

        let response = await service.answerQuestion("What sprint meetings did I have?", context: context)

        #expect(response != nil)
        #expect(mockRAG.searchCallCount == 1)
        #expect(mockRAG.lastQuery == "What sprint meetings did I have?")
    }

    @Test("Does not sync when calendar access is denied")
    func noSyncWhenDenied() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockCalendar = MockCalendarService()
        mockCalendar.mockAuthorizationStatus = .denied

        let service = MeetingContextService(
            calendarService: mockCalendar,
            ragService: MockRAGService(),
            embeddingService: MockEmbeddingService(),
            summarizationService: MockSummarizationService()
        )

        await service.syncCalendarEvents(context: context)

        #expect(mockCalendar.fetchEventsCallCount == 0)
    }
}
