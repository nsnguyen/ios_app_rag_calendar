---
name: calendar-integration
description: Integrate EventKit and EventKitUI into the iOS 18+ SwiftUI planner app for reading calendar events, displaying native calendar UI, and syncing event data to SwiftData. This skill should be used when working on calendar access, event fetching, authorization, or EventKitUI presentation.
---

# Calendar Integration

## Overview

Implement full calendar integration using EventKit (data access) and EventKitUI (native calendar views) in the SwiftUI planner app. The app reads the user's calendar, syncs events to local SwiftData MeetingRecord models, and presents Apple's native event editing/viewing UI.

## Authorization

### Request Access (iOS 17+ API)

```swift
import EventKit

@Observable
final class CalendarService {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        try await store.requestFullAccessToEvents()
    }

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }
}
```

Critical notes:
- Use `requestFullAccessToEvents()` — the iOS 17+ replacement. The old `requestAccess(to:completion:)` silently returns `false` on iOS 17+ even when granted.
- `NSCalendarsFullAccessUsageDescription` must be in Info.plist (not the old `NSCalendarsUsageDescription`).
- Check `authorizationStatus` before fetching. Handle `.denied` with a Settings deep-link.

### Handle Permission States

```swift
switch EKEventStore.authorizationStatus(for: .event) {
case .notDetermined:
    // Show explanation, then request
case .fullAccess:
    // Proceed with fetching
case .denied, .restricted:
    // Show "Open Settings" button
    if let url = URL(string: UIApplication.openSettingsURLString) {
        await UIApplication.shared.open(url)
    }
case .writeOnly:
    // iOS 17+ can grant write-only; need full access for reading
@unknown default:
    break
}
```

## Fetching Events

### Date Range Queries

```swift
func fetchEvents(from start: Date, to end: Date, calendars: [EKCalendar]? = nil) -> [EKEvent] {
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
    return store.events(matching: predicate)
}
```

Gotchas:
- `predicateForEvents` has a **maximum range of 4 years**. Wider ranges silently return empty results.
- The returned array is **not sorted**. Sort by `startDate` explicitly.
- For batch-loading a month view, fetch the full month in one call rather than day-by-day.

### Extracting Attendee Data

```swift
func extractAttendees(from event: EKEvent) -> [(name: String, email: String, status: EKParticipantStatus)] {
    guard let attendees = event.attendees else { return [] }
    return attendees.map { participant in
        let name = participant.name ?? "Unknown"
        // Email extraction is indirect — use URL
        let email = participant.url.absoluteString
            .replacingOccurrences(of: "mailto:", with: "")
        return (name: name, email: email, status: participant.participantStatus)
    }
}
```

Non-obvious:
- `EKParticipant.emailAddress` is **deprecated** and may return nil. Use `participant.url` which contains `mailto:email@example.com`.
- `participant.name` can be nil for external attendees.
- Attendee data is only available when the event is fetched from a CalDAV or Exchange calendar. Local-only calendars may have no attendees.

### Event Identifier Mapping

```swift
// Use eventIdentifier for persistent mapping to MeetingRecord
let persistentID = event.eventIdentifier
// NOT calendarItemIdentifier — that can change across syncs
```

`eventIdentifier` is stable across calendar syncs and device restores. `calendarItemIdentifier` is a local database identifier that changes when the calendar re-syncs.

## EventKitUI in SwiftUI

### Event View Controller

```swift
struct EventDetailView: UIViewControllerRepresentable {
    let event: EKEvent

    func makeUIViewController(context: Context) -> EKEventViewController {
        let vc = EKEventViewController()
        vc.event = event
        vc.allowsEditing = true
        vc.allowsCalendarPreview = true
        return vc
    }

    func updateUIViewController(_ uiViewController: EKEventViewController, context: Context) {}
}
```

### Event Edit Controller

```swift
struct EventEditView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let store: EKEventStore
    var event: EKEvent?

    func makeUIViewController(context: Context) -> UINavigationController {
        let editVC = EKEventEditViewController()
        editVC.eventStore = store
        editVC.event = event  // nil for new event
        editVC.editViewDelegate = context.coordinator
        return UINavigationController(rootViewController: editVC)
    }

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func eventEditViewController(_ controller: EKEventEditViewController,
                                      didCompleteWith action: EKEventEditViewAction) {
            dismiss()
        }
    }
}
```

Present via `.sheet`: ``.sheet(isPresented: $showEditor) { EventEditView(store: store) }``

## Staying in Sync

### Listen for External Changes

```swift
NotificationCenter.default.publisher(for: .EKEventStoreChanged)
    .sink { [weak self] _ in
        self?.refreshEvents()
    }
```

Critical: After receiving `EKEventStoreChanged`, the `EKEventStore` instance may be stale. Re-fetch events using the same store instance — do NOT create a new `EKEventStore` unless absolutely necessary (creating stores is expensive).

### Sync Pipeline

When events are fetched or updated:
1. Fetch `EKEvent` objects for the relevant date range
2. For each event, check if a `MeetingRecord` exists with matching `eventIdentifier`
3. If exists: update title, dates, location, attendees if changed
4. If new: create `MeetingRecord`, trigger embedding generation via RAG pipeline
5. Handle deleted events: mark orphaned `MeetingRecord` entries (keep data, flag as deleted from calendar)

## Edge Cases

- **All-day events**: `event.isAllDay` is true. `startDate` is midnight, `endDate` is midnight next day. Display differently in timeline.
- **Recurring events**: Each occurrence has the same `eventIdentifier`. Use `occurrenceDate` to distinguish instances. Do not create duplicate MeetingRecords for the same occurrence.
- **Declined events**: Check `event.status == .canceled` and attendee's `participantStatus == .declined`. Optionally hide or dim in the UI.
- **Multiple calendars**: Let users choose which calendars to include. Store preferences using calendar `calendarIdentifier` (stable) not calendar title.
- **Calendar permission revoked**: The app can receive `.denied` after previously having `.fullAccess`. Handle gracefully — show existing cached data with a banner to re-enable.
