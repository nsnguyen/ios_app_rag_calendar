import Foundation
import SwiftData

@Model
final class Tag {
    #Unique<Tag>([\.name])

    var name: String
    var color: String // hex color string
    var createdAt: Date

    var meetingRecords: [MeetingRecord] = []
    var notes: [Note] = []

    init(name: String, color: String = "6B8F71") {
        self.name = name
        self.color = color
        self.createdAt = Date()
    }
}
