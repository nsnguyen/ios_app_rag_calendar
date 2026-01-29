import Foundation
import SwiftData

@Model
final class Person {
    #Unique<Person>([\.email])

    var email: String
    var name: String
    var meetingCount: Int
    var lastSeenDate: Date?
    var createdAt: Date

    var meetings: [MeetingRecord] = []

    init(
        email: String,
        name: String,
        meetingCount: Int = 0,
        lastSeenDate: Date? = nil
    ) {
        self.email = email
        self.name = name
        self.meetingCount = meetingCount
        self.lastSeenDate = lastSeenDate
        self.createdAt = Date()
    }
}
