import EventKit
import Foundation
import SwiftData

protocol MeetingContextServiceProtocol {
    func syncCalendarEvents(context: ModelContext) async
    func answerQuestion(_ question: String, context: ModelContext) async -> QueryResponse?
    func generateBrief(for meeting: MeetingRecord, context: ModelContext) async -> MeetingBrief?
    func startBackgroundSync(context: ModelContext)
    func generateTimeline(for date: Date, context: ModelContext) -> [TimelineEntry]
}

@Observable
final class MeetingContextService: MeetingContextServiceProtocol {
    private let calendarService: CalendarServiceProtocol
    private let ragService: RAGServiceProtocol
    private let embeddingService: EmbeddingServiceProtocol
    private let summarizationService: SummarizationServiceProtocol

    private(set) var isSyncing = false
    private var syncTask: Task<Void, Never>?

    init(
        calendarService: CalendarServiceProtocol,
        ragService: RAGServiceProtocol,
        embeddingService: EmbeddingServiceProtocol,
        summarizationService: SummarizationServiceProtocol
    ) {
        self.calendarService = calendarService
        self.ragService = ragService
        self.embeddingService = embeddingService
        self.summarizationService = summarizationService
    }

    // MARK: - Calendar Sync

    func syncCalendarEvents(context: ModelContext) async {
        guard calendarService.authorizationStatus == .fullAccess else { return }

        isSyncing = true
        defer { isSyncing = false }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: now)!

        let calendarEvents = calendarService.fetchEvents(from: startDate, to: endDate)

        for eventData in calendarEvents {
            await upsertMeeting(from: eventData, context: context)
        }

        try? context.save()
    }

    private func upsertMeeting(from event: CalendarEventData, context: ModelContext) async {
        let identifier = event.eventIdentifier
        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { $0.eventIdentifier == identifier }
        )

        let existing = try? context.fetch(descriptor).first

        let meeting: MeetingRecord
        if let existing {
            existing.title = event.title
            existing.startDate = event.startDate
            existing.endDate = event.endDate
            existing.location = event.location
            existing.isAllDay = event.isAllDay
            existing.updatedAt = Date()
            meeting = existing
        } else {
            meeting = MeetingRecord(
                eventIdentifier: event.eventIdentifier,
                title: event.title,
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                isAllDay: event.isAllDay
            )
            context.insert(meeting)
        }

        // Upsert attendees
        for attendee in event.attendeeEmails {
            let email = attendee.email
            let personDescriptor = FetchDescriptor<Person>(
                predicate: #Predicate { $0.email == email }
            )
            let person: Person
            if let existing = try? context.fetch(personDescriptor).first {
                existing.name = attendee.name
                existing.lastSeenDate = event.startDate
                person = existing
            } else {
                person = Person(
                    email: attendee.email,
                    name: attendee.name,
                    meetingCount: 0,
                    lastSeenDate: event.startDate
                )
                context.insert(person)
            }
            if !meeting.attendees.contains(where: { $0.email == person.email }) {
                meeting.attendees.append(person)
                person.meetingCount += 1
            }
        }

        // Index for RAG (background)
        ragService.indexMeetingRecord(meeting, context: context)
    }

    // MARK: - Query

    func answerQuestion(_ question: String, context: ModelContext) async -> QueryResponse? {
        let results = ragService.search(query: question, topK: 5, context: context)
        guard !results.isEmpty else { return nil }

        let answer = results.map(\.chunkText).joined(separator: "\n\n")
        return QueryResponse(
            answer: answer,
            sources: results,
            confidence: results.first?.score ?? 0
        )
    }

    // MARK: - Brief

    func generateBrief(for meeting: MeetingRecord, context: ModelContext) async -> MeetingBrief? {
        // Find previous meetings with same attendees
        let attendeeEmails = Set(meeting.attendees.map(\.email))
        let descriptor = FetchDescriptor<MeetingRecord>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let allMeetings = (try? context.fetch(descriptor)) ?? []
        let previousMeetings = allMeetings.filter { prev in
            prev.eventIdentifier != meeting.eventIdentifier &&
            prev.startDate < meeting.startDate &&
            prev.attendees.contains(where: { attendeeEmails.contains($0.email) })
        }

        return await summarizationService.generateMeetingBrief(
            for: meeting,
            previousMeetings: Array(previousMeetings.prefix(5))
        )
    }

    // MARK: - Background Sync

    func startBackgroundSync(context: ModelContext) {
        syncTask?.cancel()
        syncTask = Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            await self.syncCalendarEvents(context: context)

            // Listen for calendar changes
            let center = NotificationCenter.default
            for await _ in center.notifications(named: .EKEventStoreChanged) {
                guard !Task.isCancelled else { break }
                await self.syncCalendarEvents(context: context)
            }
        }
    }

    // MARK: - Timeline

    func generateTimeline(for date: Date, context: ModelContext) -> [TimelineEntry] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay
        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { meeting in
                meeting.startDate >= startOfDay && meeting.startDate <= endOfDay
            },
            sortBy: [SortDescriptor(\.startDate)]
        )

        guard let meetings = try? context.fetch(descriptor) else { return [] }
        return meetings.map { TimelineEntry(from: $0) }
    }
}
