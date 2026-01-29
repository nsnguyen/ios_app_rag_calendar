import Foundation
import SwiftData

@Model
final class EmbeddingRecord {
    var chunkText: String
    var vectorData: Data // [Double] encoded
    var sourceType: String // "meeting", "note"
    var chunkIndex: Int
    var createdAt: Date

    var meetingRecord: MeetingRecord?
    var note: Note?

    init(
        chunkText: String,
        vector: [Double],
        sourceType: String,
        chunkIndex: Int = 0,
        meetingRecord: MeetingRecord? = nil,
        note: Note? = nil
    ) {
        self.chunkText = chunkText
        self.vectorData = vector.toData()
        self.sourceType = sourceType
        self.chunkIndex = chunkIndex
        self.meetingRecord = meetingRecord
        self.note = note
        self.createdAt = Date()
    }

    var vector: [Double] {
        get { [Double].fromData(vectorData) }
        set { vectorData = newValue.toData() }
    }
}
