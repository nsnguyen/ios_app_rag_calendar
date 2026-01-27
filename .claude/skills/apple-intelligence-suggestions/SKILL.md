---
name: apple-intelligence-suggestions
description: Integrate CoreSpotlight indexing, NSUserActivity donations, and proactive suggestions for Spotlight search, lock screen, and system-wide discovery of meetings and notes. This skill should be used when implementing Spotlight indexing, search suggestions, deep linking from Spotlight, or proactive content surfacing.
---

# Apple Intelligence — Suggestions & Spotlight

## Overview

Make app content discoverable system-wide through CoreSpotlight indexing, NSUserActivity donations, and App Intents donations. Meetings and notes appear in Spotlight search, on the lock screen, and in Siri Suggestions.

## CoreSpotlight Indexing

### Index Meeting Records

```swift
import CoreSpotlight
import MobileCoreServices

func indexMeetingRecord(_ record: MeetingRecord) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
    attributeSet.title = record.title
    attributeSet.contentDescription = [
        record.purpose,
        record.outcomes,
        "Attendees: \(record.attendees.map(\.name).joined(separator: ", "))"
    ].compactMap { $0 }.joined(separator: ". ")
    attributeSet.startDate = record.startDate
    attributeSet.endDate = record.endDate
    attributeSet.supportsNavigation = true

    if let location = record.location {
        attributeSet.namedLocation = location
    }

    let item = CSSearchableItem(
        uniqueIdentifier: "meeting:\(record.eventIdentifier)",
        domainIdentifier: "com.app.meetings",
        attributeSet: attributeSet
    )
    item.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: record.startDate)

    CSSearchableIndex.default().indexSearchableItems([item])
}
```

### Index Notes

```swift
func indexNote(_ note: Note) {
    let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
    attributeSet.title = note.title
    attributeSet.contentDescription = String(note.plainText.prefix(200))
    attributeSet.textContent = note.plainText
    attributeSet.contentModificationDate = note.updatedAt

    if let meetingTitle = note.meetingRecord?.title {
        attributeSet.keywords = [meetingTitle]
    }

    let item = CSSearchableItem(
        uniqueIdentifier: "note:\(note.persistentModelID.hashValue)",
        domainIdentifier: "com.app.notes",
        attributeSet: attributeSet
    )

    CSSearchableIndex.default().indexSearchableItems([item])
}
```

### Batch Indexing on First Launch

```swift
func performInitialIndex(context: ModelContext) {
    let meetings = try? context.fetch(FetchDescriptor<MeetingRecord>())
    let notes = try? context.fetch(FetchDescriptor<Note>())

    var items: [CSSearchableItem] = []
    meetings?.forEach { items.append(createSearchableItem(for: $0)) }
    notes?.forEach { items.append(createSearchableItem(for: $0)) }

    CSSearchableIndex.default().indexSearchableItems(items) { error in
        if let error { print("Indexing error: \(error)") }
    }
}
```

Gotchas:
- **Index size limit**: CoreSpotlight allows thousands of items per app, but keep `contentDescription` under 300 characters for performance.
- **Expiration**: Set `expirationDate` on items. Old meetings should expire after ~1 year to keep the index lean.
- **Deduplication**: Use consistent `uniqueIdentifier` format (`"meeting:\(id)"`) to avoid duplicate entries on re-index.

### Cleanup on Delete

```swift
func removeFromIndex(meetingIdentifier: String) {
    CSSearchableIndex.default().deleteSearchableItems(
        withIdentifiers: ["meeting:\(meetingIdentifier)"]
    )
}

func removeAllAppItems() {
    CSSearchableIndex.default().deleteSearchableItems(
        withDomainIdentifiers: ["com.app.meetings", "com.app.notes"]
    )
}
```

## NSUserActivity

### Donate Activities for Suggestions

```swift
func donateViewMeetingActivity(_ record: MeetingRecord) {
    let activity = NSUserActivity(activityType: "com.app.viewMeeting")
    activity.title = record.title
    activity.userInfo = ["eventIdentifier": record.eventIdentifier]
    activity.isEligibleForSearch = true
    activity.isEligibleForPrediction = true
    activity.persistentIdentifier = "meeting:\(record.eventIdentifier)"

    // Keywords for Spotlight
    activity.keywords = Set([record.title] + record.attendees.map(\.name))

    // Searchable attributes
    let attributes = CSSearchableItemAttributeSet(contentType: .content)
    attributes.title = record.title
    attributes.contentDescription = record.purpose ?? "Meeting on \(record.startDate.formatted())"
    activity.contentAttributeSet = attributes

    activity.becomeCurrent()
}
```

Key details:
- `isEligibleForPrediction = true` enables Siri Suggestions (lock screen, Spotlight top hits)
- `becomeCurrent()` donates the activity. Call when the user views a meeting or note.
- `persistentIdentifier` allows updating/deleting the activity later.
- The system learns usage patterns and surfaces frequently accessed items proactively.

### Activity Continuation in SwiftUI

Handle taps on Spotlight results:

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            // ... views
        }
        .onContinueUserActivity("com.app.viewMeeting") { activity in
            guard let eventId = activity.userInfo?["eventIdentifier"] as? String else { return }
            // Navigate to meeting detail
            navigationPath.append(MeetingRoute.detail(eventIdentifier: eventId))
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return }
            // Parse "meeting:xxx" or "note:xxx" format
            if identifier.hasPrefix("meeting:") {
                let eventId = String(identifier.dropFirst("meeting:".count))
                navigationPath.append(MeetingRoute.detail(eventIdentifier: eventId))
            } else if identifier.hasPrefix("note:") {
                // Navigate to note
            }
        }
    }
}
```

`CSSearchableItemActionType` handles taps on CoreSpotlight-indexed items. `onContinueUserActivity` handles NSUserActivity-donated items. Both should be present.

## App Intents Donations

Donate completed actions to improve suggestion ranking:

```swift
// After user views a meeting, donate the interaction
let intent = QueryMeetingIntent()
intent.question = "What was \(record.title) about?"
let interaction = INInteraction(intent: intent, response: nil)
interaction.donate()
```

This teaches the system which intents the user uses frequently, improving their ranking in Siri Suggestions.

## In-App Spotlight Search

Use `CSSearchQuery` for Spotlight-powered search within the app:

```swift
func spotlightSearch(query: String) async -> [CSSearchableItem] {
    await withCheckedContinuation { continuation in
        var results: [CSSearchableItem] = []
        let searchQuery = CSSearchQuery(
            queryString: query,
            queryContext: .init(fetchAttributes: ["title", "contentDescription"])
        )
        searchQuery.foundItemsHandler = { items in
            results.append(contentsOf: items)
        }
        searchQuery.completionHandler = { _ in
            continuation.resume(returning: results)
        }
        searchQuery.start()
    }
}
```

This provides fast, indexed text search as a complement to the RAG semantic search.

## Update Strategy

- **On create/update**: Re-index the item in CoreSpotlight, donate NSUserActivity
- **On delete**: Remove from CoreSpotlight index, invalidate NSUserActivity
- **On app launch**: Verify index integrity, re-index if needed (e.g., after data migration)
- **Background**: Use `CSSearchableIndex.default().fetchLastClientState()` to track sync state
