import Foundation

/// Boundary DTO for converting EKEvent data before crossing into SwiftData.
struct CalendarEventData {
    let eventIdentifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    let attendeeEmails: [(name: String, email: String)]
}
