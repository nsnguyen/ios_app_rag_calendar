---
name: meeting-context-engine
description: Build the core service layer that orchestrates calendar events, notes, people, RAG indexing, and summarization into a unified meeting context system. This skill should be used when implementing the data flow pipeline, meeting briefs, relationship tracking, background sync, or query handling.
---

# Meeting Context Engine

## Overview

The MeetingContextService is the orchestration layer — the "brain" — that ties calendar events, notes, people, RAG search, and summarization into a cohesive system. It manages the data flow pipeline from calendar fetch through embedding generation, handles natural language queries, and generates meeting briefs.

## Core Service Design

```swift
import SwiftData
import EventKit

@Observable
final class MeetingContextService {
    private let calendarService: CalendarService
    private let embeddingService: EmbeddingService
    private let ragService: RAGService
    private let modelContainer: ModelContainer

    init(
        calendarService: CalendarService,
        embeddingService: EmbeddingService,
        ragService: RAGService,
        modelContainer: ModelContainer
    ) {
        self.calendarService = calendarService
        self.embeddingService = embeddingService
        self.ragService = ragService
        self.modelContainer = modelContainer
    }
}
```

Use protocol-based dependencies for testability:

```swift
protocol CalendarServiceProtocol {
    func requestAccess() async throws -> Bool
    func fetchEvents(from: Date, to: Date) -> [EKEvent]
    var authorizationStatus: EKAuthorizationStatus { get }
}

protocol RAGServiceProtocol {
    func search(query: String, topK: Int, context: ModelContext) -> [SearchResult]
    func indexMeetingRecord(_ record: MeetingRecord, context: ModelContext) async
    func indexNote(_ note: Note, context: ModelContext) async
}
```

## Data Flow Pipeline

### Calendar Sync → MeetingRecord → Embeddings

```
Calendar (EventKit)
    ↓ fetch events
EKEvent[]
    ↓ sync to SwiftData
MeetingRecord[]
    ↓ extract chunks
Text chunks[]
    ↓ generate embeddings
EmbeddingRecord[]
    ↓ stored in SwiftData
Available for RAG search
```

### Sync Implementation

```swift
extension MeetingContextService {
    func syncCalendarEvents(from start: Date, to end: Date) async {
        let context = ModelContext(modelContainer)
        let events = calendarService.fetchEvents(from: start, to: end)

        for event in events {
            let eventId = event.eventIdentifier ?? ""
            guard !eventId.isEmpty else { continue }

            // Check for existing record
            let descriptor = FetchDescriptor<MeetingRecord>(
                predicate: #Predicate { $0.eventIdentifier == eventId }
            )
            let existing = try? context.fetch(descriptor).first

            if let record = existing {
                // Update if changed
                updateRecord(record, from: event)
            } else {
                // Create new
                let record = createRecord(from: event, context: context)
                context.insert(record)
                // Trigger async indexing
                Task.detached(priority: .utility) { [self] in
                    let bgContext = ModelContext(modelContainer)
                    await ragService.indexMeetingRecord(record, context: bgContext)
                    try? bgContext.save()
                }
            }

            // Sync attendees → Person records
            syncAttendees(from: event, context: context)
        }

        try? context.save()
    }

    private func createRecord(from event: EKEvent, context: ModelContext) -> MeetingRecord {
        let record = MeetingRecord()
        record.eventIdentifier = event.eventIdentifier
        record.title = event.title ?? "Untitled"
        record.startDate = event.startDate
        record.endDate = event.endDate
        record.location = event.location
        record.isRecurring = event.hasRecurrenceRules
        record.calendarTitle = event.calendar.title
        record.createdAt = Date()
        record.updatedAt = Date()

        // Extract organizer
        if let organizer = event.organizer {
            record.organizerName = organizer.name
            record.organizerEmail = organizer.url.absoluteString
                .replacingOccurrences(of: "mailto:", with: "")
        }

        return record
    }
}
```

### Attendee → Person Sync

```swift
private func syncAttendees(from event: EKEvent, context: ModelContext) {
    guard let attendees = event.attendees else { return }

    for participant in attendees {
        let email = participant.url.absoluteString
            .replacingOccurrences(of: "mailto:", with: "")
        let name = participant.name ?? email

        // Upsert person (unique by email)
        let descriptor = FetchDescriptor<Person>(
            predicate: #Predicate { $0.email == email }
        )

        if let person = try? context.fetch(descriptor).first {
            person.lastInteractionDate = event.startDate
            person.meetingCount += 1
        } else {
            let person = Person()
            person.email = email
            person.name = name
            person.meetingCount = 1
            person.lastInteractionDate = event.startDate
            context.insert(person)
        }
    }
}
```

## Query Handler

Route natural language questions through RAG:

```swift
struct QueryResponse {
    let answer: String
    let sources: [MeetingRecord]
    let relatedNotes: [Note]
}

extension MeetingContextService {
    func answerQuestion(_ question: String) async -> QueryResponse {
        let context = ModelContext(modelContainer)
        let results = ragService.search(query: question, topK: 5, context: context)

        // Gather unique source meetings and notes
        var meetings: [MeetingRecord] = []
        var notes: [Note] = []
        for result in results {
            if let meeting = result.embeddingRecord.meetingRecord, !meetings.contains(where: { $0.eventIdentifier == meeting.eventIdentifier }) {
                meetings.append(meeting)
            }
            if let note = result.embeddingRecord.note, !notes.contains(where: { $0.id == note.id }) {
                notes.append(note)
            }
        }

        // Assemble answer from top results
        let answerText = results.prefix(3)
            .map { $0.embeddingRecord.sourceText }
            .joined(separator: "\n\n")

        return QueryResponse(
            answer: answerText,
            sources: meetings,
            relatedNotes: notes
        )
    }
}
```

## Meeting Brief Generation

Generate a brief before an upcoming meeting:

```swift
extension MeetingContextService {
    func generateBrief(for upcomingMeeting: MeetingRecord) async -> MeetingBrief {
        let context = ModelContext(modelContainer)

        // Find past meetings with the same attendees
        let attendeeEmails = upcomingMeeting.attendees.map(\.email)
        let pastMeetings = findPastMeetings(withAttendees: attendeeEmails, context: context)

        // Find related notes
        let relatedResults = ragService.search(
            query: upcomingMeeting.title,
            topK: 5,
            context: context
        )

        return MeetingBrief(
            meetingTitle: upcomingMeeting.title,
            attendeeSummaries: generateAttendeeSummaries(attendeeEmails, context: context),
            pastMeetingCount: pastMeetings.count,
            recentTopics: extractTopics(from: pastMeetings),
            relatedNotes: relatedResults.compactMap { $0.embeddingRecord.note }
        )
    }
}

struct MeetingBrief {
    let meetingTitle: String
    let attendeeSummaries: [String]
    let pastMeetingCount: Int
    let recentTopics: [String]
    let relatedNotes: [Note]
}
```

## Background Sync

Periodically check for calendar changes:

```swift
extension MeetingContextService {
    func startBackgroundSync() {
        // Listen for calendar store changes
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: nil, queue: .main
        ) { [weak self] _ in
            Task { await self?.performIncrementalSync() }
        }
    }

    private func performIncrementalSync() async {
        let now = Date()
        let past30Days = Calendar.current.date(byAdding: .day, value: -30, to: now)!
        let future7Days = Calendar.current.date(byAdding: .day, value: 7, to: now)!
        await syncCalendarEvents(from: past30Days, to: future7Days)
    }
}
```

## Conflict Resolution

Handle externally modified/deleted calendar events:

- **Modified event**: The `eventIdentifier` stays the same. Update the `MeetingRecord` fields but preserve user-added data (notes, purpose, outcomes).
- **Deleted event**: The event disappears from EventKit fetch results. Keep the `MeetingRecord` and its embeddings — the user's notes and context are still valuable. Flag with a `calendarDeleted` property if needed.
- **Recurring event changes**: If a single occurrence is modified, it gets a new `eventIdentifier`. Track the original series via the recurring event's base identifier.

## Timeline Generation

```swift
func generateTimeline(for date: Date) -> [TimelineEntry] {
    let context = ModelContext(modelContainer)
    let start = Calendar.current.startOfDay(for: date)
    let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

    let descriptor = FetchDescriptor<MeetingRecord>(
        predicate: #Predicate { $0.startDate >= start && $0.startDate < end },
        sortBy: [SortDescriptor(\.startDate)]
    )

    let meetings = (try? context.fetch(descriptor)) ?? []
    return meetings.map { meeting in
        TimelineEntry(
            meeting: meeting,
            hasNotes: !meeting.notes.isEmpty,
            hasSummary: meeting.summary != nil,
            attendeeCount: meeting.attendees.count
        )
    }
}
```
