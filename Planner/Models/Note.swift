import Foundation
import SwiftData

@Model
final class Note {
    var title: String
    var plainText: String
    var richTextData: Data?
    var createdAt: Date
    var updatedAt: Date

    var meetingRecord: MeetingRecord?

    @Relationship(deleteRule: .cascade, inverse: \EmbeddingRecord.note)
    var embeddings: [EmbeddingRecord] = []

    @Relationship(inverse: \Tag.notes)
    var tags: [Tag] = []

    init(
        title: String = "",
        plainText: String = "",
        richTextData: Data? = nil,
        meetingRecord: MeetingRecord? = nil
    ) {
        self.title = title
        self.plainText = plainText
        self.richTextData = richTextData
        self.meetingRecord = meetingRecord
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
