import EventKit
import Foundation

enum CalendarAuthorizationStatus {
    case notDetermined
    case restricted
    case denied
    case fullAccess
    case writeOnly

    init(from status: EKAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .fullAccess: self = .fullAccess
        case .writeOnly: self = .writeOnly
        @unknown default: self = .denied
        }
    }
}

protocol CalendarServiceProtocol: Sendable {
    var authorizationStatus: CalendarAuthorizationStatus { get }
    func requestAccess() async throws -> Bool
    func fetchEvents(from startDate: Date, to endDate: Date) -> [CalendarEventData]
}
