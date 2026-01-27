---
name: apple-intelligence-siri
description: Integrate Siri and App Intents into the iOS 18+ planner app for voice-driven meeting queries, note search, and hands-free interaction. This skill should be used when implementing App Intents, Siri shortcuts, voice queries, or Shortcuts app integration.
---

# Apple Intelligence — Siri & App Intents

## Overview

Implement Siri integration using the App Intents framework (not legacy SiriKit) for the iOS 18+ planner app. Users can ask Siri questions like "What was my meeting with John about?" and get answers powered by the on-device RAG engine.

## App Intent Basics

### Define an Intent

```swift
import AppIntents

struct QueryMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Meetings"
    static var description = IntentDescription("Search your meeting history using natural language")

    @Parameter(title: "Question")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search meetings for \(\.$question)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let results = await RAGService.shared.search(query: question)
        if results.isEmpty {
            return .result(dialog: "I couldn't find any meetings matching your question.")
        }
        let topResult = results[0]
        let source = topResult.embeddingRecord.sourceText
        return .result(dialog: "\(source)")
    }
}
```

Key details:
- `@Parameter` properties are what Siri extracts from natural language. Use descriptive `title` values.
- `parameterSummary` defines the sentence structure shown in Shortcuts app.
- Return `.result(dialog:)` for text responses Siri reads aloud.

### Define App Entities

For Siri to reference meetings and notes by name, define `AppEntity`:

```swift
struct MeetingEntity: AppEntity {
    static var defaultQuery = MeetingEntityQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Meeting")

    var id: String  // eventIdentifier
    var title: String
    var date: Date

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(date.formatted(date: .abbreviated, time: .shortened))")
    }
}

struct MeetingEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MeetingEntity] {
        // Fetch from SwiftData by eventIdentifier
        let context = ModelContext(SharedModelContainer.shared)
        return identifiers.compactMap { id in
            let descriptor = FetchDescriptor<MeetingRecord>(
                predicate: #Predicate { $0.eventIdentifier == id }
            )
            guard let record = try? context.fetch(descriptor).first else { return nil }
            return MeetingEntity(id: record.eventIdentifier, title: record.title, date: record.startDate)
        }
    }

    func suggestedEntities() async throws -> [MeetingEntity] {
        // Return recent meetings for Siri suggestions
        let context = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<MeetingRecord>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let records = try context.fetch(descriptor).prefix(10)
        return records.map { MeetingEntity(id: $0.eventIdentifier, title: $0.title, date: $0.startDate) }
    }
}
```

Non-obvious:
- `suggestedEntities()` powers Siri's autocomplete when the user starts speaking a meeting name.
- Entity queries run in a separate process. Access SwiftData via a shared `ModelContainer`, not `@Environment`.

### Connecting to RAG

The key integration point — route Siri queries through the RAG engine:

```swift
struct AskAboutMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask About Meetings"
    static var description = IntentDescription("Ask a question about your past meetings")

    @Parameter(title: "Question")
    var question: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let ragService = RAGService()
        let context = ModelContext(SharedModelContainer.shared)
        let results = ragService.search(query: question, topK: 3, context: context)

        guard !results.isEmpty else {
            return .result(dialog: "I don't have any information about that from your meetings.")
        }

        // Combine top results into a response
        let combined = results.map { $0.embeddingRecord.sourceText }.joined(separator: ". ")
        return .result(dialog: "\(combined)")
    }
}
```

## App Shortcuts Provider

Register shortcuts with predefined phrases:

```swift
struct AppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskAboutMeetingIntent(),
            phrases: [
                "What was my meeting about in \(.applicationName)",
                "Ask \(.applicationName) about my meetings",
                "Search meetings in \(.applicationName)",
            ],
            shortTitle: "Ask About Meetings",
            systemImageName: "calendar.badge.magnifyingglass"
        )

        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "Take a note with \(.applicationName)",
            ],
            shortTitle: "Create Note",
            systemImageName: "note.text.badge.plus"
        )

        AppShortcut(
            intent: SearchNotesIntent(),
            phrases: [
                "Search my notes in \(.applicationName)",
                "Find a note in \(.applicationName)",
            ],
            shortTitle: "Search Notes",
            systemImageName: "magnifyingglass"
        )
    }
}
```

Rules:
- Every phrase **must** include `\(.applicationName)` at least once.
- Maximum 10 `AppShortcut` entries. System ignores extras.
- `AppShortcutsProvider` must be a **top-level struct**, not nested.
- Phrases should be natural language the user would actually say.

## SiriTipView

Teach users what they can say:

```swift
SiriTipView(intent: AskAboutMeetingIntent())
    .siriTipViewStyle(.automatic)
```

Place in the search view or meeting detail view. The tip auto-dismisses after the user has used the shortcut.

## Shared ModelContainer

App Intents run in a separate process. Create a shared container:

```swift
enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            MeetingRecord.self, Note.self, Person.self,
            EmbeddingRecord.self, Tag.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()
}
```

Use `SharedModelContainer.shared` in all App Intent `perform()` methods.

## Configuration Requirements

1. **Entitlement**: `com.apple.developer.siri = true` in `.entitlements` file
2. **Info.plist**: `NSSiriUsageDescription` with descriptive text
3. **Xcode**: Enable Siri capability in Signing & Capabilities
4. **Build settings**: Do not include `-disable-reflection-metadata` in Other Swift Flags

## Error Handling

```swift
func perform() async throws -> some IntentResult & ProvidesDialog {
    guard CalendarService.shared.authorizationStatus == .fullAccess else {
        return .result(dialog: "I need calendar access to answer that. Please open the app to grant permission.")
    }
    // ... perform query
}
```

Handle gracefully: no results, permission denied, RAG service unavailable. Siri responses should be conversational, not technical error messages.
