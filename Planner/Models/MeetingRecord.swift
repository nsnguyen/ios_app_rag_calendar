import Foundation
import SwiftData

@Model
final class MeetingRecord {
    #Unique<MeetingRecord>([\.eventIdentifier])

    var eventIdentifier: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var meetingNotes: String?
    var purpose: String?
    var outcomes: String?
    var actionItems: String?
    var summary: String?
    var sourceType: String // "calendar", "manual"
    var isAllDay: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Note.meetingRecord)
    var notes: [Note] = []

    @Relationship(inverse: \Person.meetings)
    var attendees: [Person] = []

    @Relationship(deleteRule: .cascade, inverse: \EmbeddingRecord.meetingRecord)
    var embeddings: [EmbeddingRecord] = []

    @Relationship(inverse: \Tag.meetingRecords)
    var tags: [Tag] = []

    init(
        eventIdentifier: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        meetingNotes: String? = nil,
        purpose: String? = nil,
        outcomes: String? = nil,
        actionItems: String? = nil,
        summary: String? = nil,
        sourceType: String = "calendar",
        isAllDay: Bool = false
    ) {
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.meetingNotes = meetingNotes
        self.purpose = purpose
        self.outcomes = outcomes
        self.actionItems = actionItems
        self.summary = summary
        self.sourceType = sourceType
        self.isAllDay = isAllDay
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
