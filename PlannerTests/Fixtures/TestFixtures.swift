import Foundation
@testable import Planner

enum TestFixtures {

    // MARK: - MeetingRecord

    static func makeMeeting(
        eventIdentifier: String = "test-event-\(UUID().uuidString)",
        title: String = "Test Meeting",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        location: String? = "Conference Room A",
        purpose: String? = "Discuss project progress",
        outcomes: String? = "Agreed on next steps",
        actionItems: String? = "TODO: Follow up with team",
        sourceType: String = "calendar",
        isAllDay: Bool = false
    ) -> MeetingRecord {
        MeetingRecord(
            eventIdentifier: eventIdentifier,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            purpose: purpose,
            outcomes: outcomes,
            actionItems: actionItems,
            sourceType: sourceType,
            isAllDay: isAllDay
        )
    }

    // MARK: - Note

    static func makeNote(
        title: String = "Test Note",
        plainText: String = "This is a test note with some content for testing purposes.",
        richTextData: Data? = nil,
        meetingRecord: MeetingRecord? = nil
    ) -> Note {
        Note(
            title: title,
            plainText: plainText,
            richTextData: richTextData,
            meetingRecord: meetingRecord
        )
    }

    // MARK: - Person

    static func makePerson(
        email: String = "test@example.com",
        name: String = "John Doe",
        meetingCount: Int = 5,
        lastSeenDate: Date? = Date()
    ) -> Person {
        Person(
            email: email,
            name: name,
            meetingCount: meetingCount,
            lastSeenDate: lastSeenDate
        )
    }

    // MARK: - Tag

    static func makeTag(
        name: String = "work",
        color: String = "6B8F71"
    ) -> Tag {
        Tag(name: name, color: color)
    }

    // MARK: - CalendarEventData

    static func makeCalendarEventData(
        eventIdentifier: String = "cal-event-\(UUID().uuidString)",
        title: String = "Calendar Event",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(3600),
        location: String? = "Room B",
        isAllDay: Bool = false,
        attendeeEmails: [(name: String, email: String)] = [
            (name: "Alice", email: "alice@example.com"),
            (name: "Bob", email: "bob@example.com"),
        ]
    ) -> CalendarEventData {
        CalendarEventData(
            eventIdentifier: eventIdentifier,
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            isAllDay: isAllDay,
            attendeeEmails: attendeeEmails
        )
    }

    // MARK: - InspirationPhrase

    static func makeInspirationPhrase(
        text: String = "Stay focused today.",
        tone: InspirationPhrase.Tone = .warm
    ) -> InspirationPhrase {
        InspirationPhrase(text: text, tone: tone)
    }
}
