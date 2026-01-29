import Foundation

struct TimelineEntry: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let attendeeNames: [String]
    let isAllDay: Bool
    let hasNotes: Bool
    let hasSummary: Bool
    let tagNames: [String]
    let meetingRecord: MeetingRecord

    init(from meeting: MeetingRecord) {
        self.id = meeting.eventIdentifier
        self.title = meeting.title
        self.startDate = meeting.startDate
        self.endDate = meeting.endDate
        self.location = meeting.location
        self.attendeeNames = meeting.attendees.map(\.name)
        self.isAllDay = meeting.isAllDay
        self.hasNotes = !meeting.notes.isEmpty
        self.hasSummary = meeting.summary != nil
        self.tagNames = meeting.tags.map(\.name)
        self.meetingRecord = meeting
    }
}
