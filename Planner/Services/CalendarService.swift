import EventKit
import Foundation

final class CalendarService: CalendarServiceProtocol, @unchecked Sendable {
    private let eventStore = EKEventStore()

    var authorizationStatus: CalendarAuthorizationStatus {
        CalendarAuthorizationStatus(from: EKEventStore.authorizationStatus(for: .event))
    }

    func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEventData] {
        let calendars = eventStore.calendars(for: .event)
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        let events = eventStore.events(matching: predicate)

        return events.compactMap { event in
            let identifier = event.eventIdentifier ?? ""
            guard !identifier.isEmpty else { return nil }

            let attendees: [(name: String, email: String)] = (event.attendees ?? []).compactMap { attendee in
                let url = attendee.url
                guard url.scheme == "mailto",
                      let email = url.absoluteString.components(separatedBy: ":").last else {
                    return nil
                }
                let name = attendee.name ?? email
                return (name: name, email: email)
            }

            return CalendarEventData(
                eventIdentifier: identifier,
                title: event.title ?? "Untitled",
                startDate: event.startDate,
                endDate: event.endDate,
                location: event.location,
                isAllDay: event.isAllDay,
                attendeeEmails: attendees
            )
        }
    }
}
