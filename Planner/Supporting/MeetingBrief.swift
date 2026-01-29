import Foundation

struct MeetingBrief: Identifiable {
    let id = UUID()
    let meetingTitle: String
    let meetingDate: Date
    let attendeeSummary: String
    let previousMeetingsSummary: String?
    let actionItemsFromLastTime: [String]
    let suggestedTopics: [String]
    let relationshipContext: String?
}
