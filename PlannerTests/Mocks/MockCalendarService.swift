import Foundation
@testable import Planner

final class MockCalendarService: CalendarServiceProtocol, @unchecked Sendable {
    var mockAuthorizationStatus: CalendarAuthorizationStatus = .fullAccess
    var mockEvents: [CalendarEventData] = []
    var requestAccessResult: Bool = true
    var requestAccessError: Error?
    var requestAccessCallCount = 0
    var fetchEventsCallCount = 0

    var authorizationStatus: CalendarAuthorizationStatus {
        mockAuthorizationStatus
    }

    func requestAccess() async throws -> Bool {
        requestAccessCallCount += 1
        if let error = requestAccessError {
            throw error
        }
        return requestAccessResult
    }

    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEventData] {
        fetchEventsCallCount += 1
        return mockEvents
    }
}
