---
name: testing-strategy
description: Design and implement tests using Swift Testing and XCTest for the iOS 18+ planner app, covering SwiftData models, EventKit mocking, RAG pipeline, and UI tests. This skill should be used when writing unit tests, UI tests, creating test fixtures, or designing testable architecture.
---

# Testing Strategy

## Overview

Test the planner app using Swift Testing (`@Test`, `#expect`, `@Suite`) for unit/integration tests and XCUITest for UI tests. Design testable architecture with protocol-based services so EventKit, RAG, and summarization can be mocked.

## Swift Testing Basics (iOS 18+)

```swift
import Testing
@testable import MeetingMind

@Suite("MeetingRecord Tests")
struct MeetingRecordTests {
    @Test("Creates meeting from calendar event data")
    func createFromEvent() {
        let record = MeetingRecord()
        record.title = "Standup"
        record.startDate = Date()
        record.endDate = Date().addingTimeInterval(3600)
        record.eventIdentifier = "test-123"
        #expect(record.title == "Standup")
        #expect(record.notes.isEmpty)
    }
}
```

Use `@Test(arguments:)` for parameterized tests:

```swift
@Test("Chunk text at various lengths", arguments: [
    ("Short text", 1),
    ("This is a longer text that has multiple sentences. It should be chunked properly.", 1),
])
func chunkText(input: String, expectedChunks: Int) {
    let chunks = RAGService.chunkText(input, title: "Test")
    #expect(chunks.count == expectedChunks)
}
```

## SwiftData Testing

Use in-memory `ModelConfiguration` for isolated, fast tests:

```swift
@Suite("SwiftData Model Tests")
struct ModelTests {
    let container: ModelContainer

    init() throws {
        let schema = Schema([MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    @Test("Meeting record relationships")
    func meetingRelationships() throws {
        let context = ModelContext(container)
        let meeting = MeetingRecord()
        meeting.eventIdentifier = "test-1"
        meeting.title = "Test Meeting"
        meeting.startDate = Date()
        meeting.endDate = Date()
        meeting.isRecurring = false
        meeting.createdAt = Date()
        meeting.updatedAt = Date()

        let note = Note()
        note.title = "Test Note"
        note.plainText = "Some content"
        note.createdAt = Date()
        note.updatedAt = Date()
        note.meetingRecord = meeting

        context.insert(meeting)
        context.insert(note)
        try context.save()

        #expect(meeting.notes.count == 1)
        #expect(meeting.notes.first?.title == "Test Note")
    }

    @Test("Unique constraint upserts")
    func uniqueConstraint() throws {
        let context = ModelContext(container)
        let meeting1 = MeetingRecord()
        meeting1.eventIdentifier = "same-id"
        meeting1.title = "Original"
        meeting1.startDate = Date()
        meeting1.endDate = Date()
        meeting1.isRecurring = false
        meeting1.createdAt = Date()
        meeting1.updatedAt = Date()
        context.insert(meeting1)
        try context.save()

        let meeting2 = MeetingRecord()
        meeting2.eventIdentifier = "same-id"
        meeting2.title = "Updated"
        meeting2.startDate = Date()
        meeting2.endDate = Date()
        meeting2.isRecurring = false
        meeting2.createdAt = Date()
        meeting2.updatedAt = Date()
        context.insert(meeting2)
        try context.save()

        // @Attribute(.unique) causes upsert
        let descriptor = FetchDescriptor<MeetingRecord>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 1)
    }
}
```

## Mocking EventKit

`EKEventStore` is not easily mockable. Wrap it with a protocol:

```swift
protocol CalendarServiceProtocol: Sendable {
    func requestAccess() async throws -> Bool
    func fetchEvents(from: Date, to: Date) -> [EKEvent]
    var authorizationStatus: EKAuthorizationStatus { get }
}

// Production
final class CalendarService: CalendarServiceProtocol { ... }

// Test mock
final class MockCalendarService: CalendarServiceProtocol {
    var mockEvents: [MockEvent] = []
    var mockAuthStatus: EKAuthorizationStatus = .fullAccess

    func requestAccess() async throws -> Bool { true }
    var authorizationStatus: EKAuthorizationStatus { mockAuthStatus }
    func fetchEvents(from: Date, to: Date) -> [EKEvent] { [] }
}
```

Since `EKEvent` cannot be instantiated in tests (requires an `EKEventStore`), create a data transfer struct:

```swift
struct CalendarEventData {
    let identifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let attendeeEmails: [String]
    let location: String?
}

// Service converts EKEvent → CalendarEventData at the boundary
// Tests work with CalendarEventData directly
```

## RAG Pipeline Testing

### Cosine Similarity Tests

```swift
@Suite("Cosine Similarity")
struct SimilarityTests {
    @Test("Identical vectors have similarity 1.0")
    func identicalVectors() {
        let v = [1.0, 0.0, 0.0, 0.0]
        let similarity = cosineSimilarity(v, v)
        #expect(abs(similarity - 1.0) < 0.001)
    }

    @Test("Orthogonal vectors have similarity 0.0")
    func orthogonalVectors() {
        let a = [1.0, 0.0]
        let b = [0.0, 1.0]
        #expect(abs(cosineSimilarity(a, b)) < 0.001)
    }

    @Test("Opposite vectors have similarity -1.0")
    func oppositeVectors() {
        let a = [1.0, 0.0]
        let b = [-1.0, 0.0]
        #expect(abs(cosineSimilarity(a, b) + 1.0) < 0.001)
    }
}
```

### Chunking Tests

```swift
@Test("Chunks meeting record fields")
func chunkMeeting() {
    let record = MeetingRecord()
    record.title = "Budget Review"
    record.purpose = "Review Q4 budget allocation"
    record.outcomes = "Approved 10% increase"
    // ...
    let chunks = RAGService.generateMeetingChunks(record)
    #expect(chunks.contains(where: { $0.contains("Budget Review") }))
    #expect(chunks.contains(where: { $0.contains("Q4 budget") }))
}
```

### Vector Data Conversion Tests

```swift
@Test("Double array roundtrips through Data")
func vectorRoundtrip() {
    let original: [Double] = [0.1, 0.2, 0.3, 0.4, 0.5]
    let data = original.asData
    let restored = data.asDoubleArray
    #expect(original == restored)
}
```

## UI Tests (XCUITest)

```swift
import XCTest

final class OnboardingUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments.append("--uitesting")
        app.launch()
    }

    func testFirstLaunchShowsOnboarding() {
        XCTAssertTrue(app.staticTexts["Calendar Access"].exists)
    }

    func testTabNavigation() {
        app.tabBars.buttons["Notes"].tap()
        XCTAssertTrue(app.navigationBars["Notes"].exists)

        app.tabBars.buttons["Search"].tap()
        XCTAssertTrue(app.navigationBars["Search"].exists)
    }

    func testCreateNote() {
        app.tabBars.buttons["Notes"].tap()
        app.buttons["New Note"].tap()
        // Verify editor appears
        XCTAssertTrue(app.textViews.firstMatch.exists)
    }
}
```

## Test Fixtures

Create reusable test data:

```swift
enum TestFixtures {
    static func makeMeeting(
        title: String = "Test Meeting",
        date: Date = Date(),
        attendees: [String] = []
    ) -> MeetingRecord {
        let record = MeetingRecord()
        record.eventIdentifier = UUID().uuidString
        record.title = title
        record.startDate = date
        record.endDate = date.addingTimeInterval(3600)
        record.isRecurring = false
        record.createdAt = Date()
        record.updatedAt = Date()
        return record
    }

    static func makeNote(
        title: String = "Test Note",
        plainText: String = "Test content"
    ) -> Note {
        let note = Note()
        note.title = title
        note.plainText = plainText
        note.createdAt = Date()
        note.updatedAt = Date()
        return note
    }
}
```

## Testing Checklist

- [ ] All SwiftData models insert/fetch/delete correctly with in-memory config
- [ ] Relationship cascades work (delete meeting → deletes embeddings)
- [ ] Unique constraints trigger upsert, not duplicate
- [ ] Cosine similarity math is correct
- [ ] Chunking produces expected number and content of chunks
- [ ] Vector Data ↔ [Double] roundtrips without precision loss
- [ ] Calendar service protocol enables mock injection
- [ ] Search returns results sorted by relevance
- [ ] UI tests pass for critical flows (onboarding, tab navigation, note creation)
