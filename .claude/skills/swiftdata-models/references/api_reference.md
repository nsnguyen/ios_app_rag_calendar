# SwiftData Schema Reference — Planner/Meeting-Recall App

## MeetingRecord

```swift
import SwiftData
import Foundation

@Model
final class MeetingRecord {
    @Attribute(.unique) var eventIdentifier: String
    var title: String
    var startDate: Date
    var endDate: Date
    var location: String?
    var organizerName: String?
    var organizerEmail: String?
    var purpose: String?
    var outcomes: String?
    var actionItems: String?
    var summary: String?
    var calendarTitle: String?
    var isRecurring: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Note.meetingRecord)
    var notes: [Note]

    @Relationship(inverse: \Person.meetings)
    var attendees: [Person]

    @Relationship(deleteRule: .cascade, inverse: \EmbeddingRecord.meetingRecord)
    var embeddings: [EmbeddingRecord]

    @Relationship(inverse: \Tag.meetingRecords)
    var tags: [Tag]

    init(
        eventIdentifier: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String? = nil,
        isRecurring: Bool = false
    ) {
        self.eventIdentifier = eventIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.isRecurring = isRecurring
        self.createdAt = .now
        self.updatedAt = .now
        self.notes = []
        self.attendees = []
        self.embeddings = []
        self.tags = []
    }
}
```

## Note

```swift
@Model
final class Note {
    var title: String
    var richTextData: Data?
    var plainText: String
    var createdAt: Date
    var updatedAt: Date

    var meetingRecord: MeetingRecord?

    @Relationship(deleteRule: .cascade, inverse: \EmbeddingRecord.note)
    var embeddings: [EmbeddingRecord]

    @Relationship(inverse: \Tag.notes)
    var tags: [Tag]

    @Transient var attributedText: NSAttributedString? {
        get {
            guard let data = richTextData else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSAttributedString.self, from: data
            )
        }
        set {
            richTextData = try? newValue.map {
                try NSKeyedArchiver.archivedData(
                    withRootObject: $0, requiringSecureCoding: false
                )
            }
        }
    }

    init(title: String = "", plainText: String = "") {
        self.title = title
        self.plainText = plainText
        self.createdAt = .now
        self.updatedAt = .now
        self.embeddings = []
        self.tags = []
    }
}
```

## Person

```swift
@Model
final class Person {
    @Attribute(.unique) var email: String
    var name: String
    var company: String?
    var role: String?
    var relationshipSummary: String?
    var lastInteractionDate: Date?
    var meetingCount: Int

    var meetings: [MeetingRecord]

    init(email: String, name: String) {
        self.email = email
        self.name = name
        self.meetingCount = 0
        self.meetings = []
    }
}
```

## EmbeddingRecord

```swift
@Model
final class EmbeddingRecord {
    var vectorData: Data
    var sourceText: String
    var sourceType: String  // "meeting" or "note"
    var chunkIndex: Int
    var createdAt: Date

    var meetingRecord: MeetingRecord?
    var note: Note?

    @Transient var vector: [Double] {
        get {
            vectorData.withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
        }
        set {
            vectorData = newValue.withUnsafeBytes { Data($0) }
        }
    }

    @Transient var dimensionCount: Int {
        vectorData.count / MemoryLayout<Double>.size
    }

    init(vectorData: Data, sourceText: String, sourceType: String, chunkIndex: Int = 0) {
        self.vectorData = vectorData
        self.sourceText = sourceText
        self.sourceType = sourceType
        self.chunkIndex = chunkIndex
        self.createdAt = .now
    }
}
```

## Tag

```swift
@Model
final class Tag {
    @Attribute(.unique) var name: String
    var color: String  // Hex string

    var meetingRecords: [MeetingRecord]
    var notes: [Note]

    init(name: String, color: String = "#007AFF") {
        self.name = name
        self.color = color
        self.meetingRecords = []
        self.notes = []
    }
}
```

## Common FetchDescriptor Patterns

### Meetings in date range

```swift
func meetingsInRange(from start: Date, to end: Date, context: ModelContext) throws -> [MeetingRecord] {
    let descriptor = FetchDescriptor<MeetingRecord>(
        predicate: #Predicate { $0.startDate >= start && $0.startDate < end },
        sortBy: [SortDescriptor(\.startDate)]
    )
    return try context.fetch(descriptor)
}
```

### Notes by tag

```swift
func notesByTag(_ tagName: String, context: ModelContext) throws -> [Note] {
    let descriptor = FetchDescriptor<Tag>(
        predicate: #Predicate { $0.name == tagName }
    )
    guard let tag = try context.fetch(descriptor).first else { return [] }
    return tag.notes
}
```

### All embeddings for similarity search

```swift
func allEmbeddings(context: ModelContext) throws -> [EmbeddingRecord] {
    let descriptor = FetchDescriptor<EmbeddingRecord>()
    return try context.fetch(descriptor)
}
```

### Top attendees by meeting count

```swift
func topAttendees(limit: Int, context: ModelContext) throws -> [Person] {
    var descriptor = FetchDescriptor<Person>(
        sortBy: [SortDescriptor(\.meetingCount, order: .reverse)]
    )
    descriptor.fetchLimit = limit
    return try context.fetch(descriptor)
}
```

## Vector Conversion Helpers

```swift
extension Array where Element == Double {
    var asData: Data {
        withUnsafeBytes { Data($0) }
    }
}

extension Data {
    var asDoubleArray: [Double] {
        withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
    }
}
```

## Cosine Similarity (Accelerate)

```swift
import Accelerate

func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
    precondition(a.count == b.count)
    var dot: Double = 0, normA: Double = 0, normB: Double = 0
    vDSP_dotprD(a, 1, b, 1, &dot, vDSP_Length(a.count))
    vDSP_dotprD(a, 1, a, 1, &normA, vDSP_Length(a.count))
    vDSP_dotprD(b, 1, b, 1, &normB, vDSP_Length(b.count))
    let denom = sqrt(normA) * sqrt(normB)
    return denom > 0 ? dot / denom : 0
}
```
