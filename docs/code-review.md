# Code Review (2026-01-27)

Full codebase audit by the iOS Developer agent. 62 Swift source files (~3,730 lines), 24 test files (~2,015 lines).

---

## Critical Issues

| ID | Issue | Location | Description |
|----|-------|----------|-------------|
| C1 | No build system | Project root | No `.xcodeproj` or `Package.swift` exists. The code cannot be compiled as-is. |
| C2 | No service dependency injection | `TimelineView:87`, `MeetingDetailView:209`, `SearchView:76`, `PersonDetailView:89`, `DataSettingsView:72`, `PermissionsSettingsView:83`, `OnboardingView:198` | Every view creates services inline (e.g., `MeetingContextService(calendarService: CalendarService(), ...)`). This spawns multiple `EKEventStore` instances, loads the NLEmbedding model multiple times, and makes `@Observable` on `MeetingContextService` useless since no view holds a shared reference. |
| C3 | meetingCount inflates on every sync | `MeetingContextService.swift:95` | `existing.meetingCount += 1` runs on every sync pass, not just when a person is newly associated with a meeting. After 10 syncs, a person who attended 1 meeting shows `meetingCount: 10`. |
| C4 | Duplicate notes on re-save | `NoteEditorView.swift:87-100` | After inserting a new `Note`, the reference is never stored back. Subsequent debounced saves see `existingNote == nil` and insert again, creating duplicates. |

---

## High Priority Issues

| ID | Issue | Location | Description |
|----|-------|----------|-------------|
| H1 | Actor boundary violation | `DataSettingsView.swift:71-82` | `Task.detached(priority: .utility)` captures `modelContext` from `@Environment`. `ModelContext` is not `Sendable` — accessing it from a detached task is undefined behavior under Swift concurrency. Should create a new `ModelContext` inside the detached task. |
| H2 | UI test launch args ignored | `ContentView.swift`, `PlannerApp.swift` | UI tests use `--skip-onboarding` and `--reset-onboarding` launch arguments, but the app never checks `ProcessInfo.processInfo.arguments`. All UI tests would fail because onboarding always shows. |
| H3 | RichTextEditor not integrated | `NoteEditorView.swift:55` | `RichTextEditor`, `FormattingToolbar`, and `RichTextHelpers` are fully built but `NoteEditorView` still uses a plain `TextEditor`. The comment says "replaced by RichTextEditor in Phase 4" but the swap was never done. |
| H4 | Notes never indexed via RAG | `NoteEditorView.swift` | `RAGService.indexNote()` exists and works, but is never called from the note save flow. Only meetings are indexed during calendar sync. Notes are invisible to semantic search. |
| H5 | Spotlight indexing is dead code | `SpotlightService.swift` | `SpotlightService.indexMeeting()` and `indexNote()` are implemented but never called from `MeetingContextService` during sync or `NoteEditorView` during save. |
| H6 | Inspiration phrase never loaded | `TimelineView.swift:9,15-17` | `inspirationPhrase` is declared as `@State` and the banner conditionally renders, but `loadTimeline()` never sets it. `InspirationService` is never used in this view. `@AppStorage("inspirationEnabled")` is also not checked. |

---

## Medium Priority Issues

| ID | Issue | Location | Description |
|----|-------|----------|-------------|
| M1 | Non-deterministic avatar colors | `PersonAvatarView.swift:29` | Uses `abs(name.hashValue)` for color selection, but `String.hashValue` is randomized per process in Swift. Avatar colors change on every app launch. Should use a deterministic hash (e.g., DJB2 or character-sum). |
| M2 | `@unchecked Sendable` on CalendarService | `CalendarService.swift:4` | `EKEventStore` is not inherently `Sendable`. Marking `CalendarService` as `@unchecked Sendable` suppresses the warning but doesn't make concurrent access safe. |
| M3 | Missing accessibility labels | Multiple views | `DateChipView`, `MeetingCardView`, `PersonAvatarView`, `InspirationBannerView`, `TagChipView` lack explicit `.accessibilityLabel()` modifiers. |
| M4 | Deprecated `UIScreen.main.bounds` | `RichTextEditor.swift:30` | `UIScreen.main.bounds.width` is deprecated in multi-window environments. Would cause issues if ported to iPad. |
| M5 | Silent error handling | `OnboardingView.swift:199`, `DataSettingsView.swift:93` | `_ = try? await service.requestAccess()` and empty `catch` blocks silently swallow errors with no user feedback. |
| M6 | Migration plan not wired | `SharedModelContainer.swift`, `SchemaVersion.swift` | `PlannerMigrationPlan` is defined but never passed to the `ModelContainer` configuration. Future schema migrations won't execute. |

---

## Low Priority Issues

| ID | Issue | Location | Description |
|----|-------|----------|-------------|
| L1 | Dangling import | `ExtensionTests.swift:110` | `import SwiftUI` at end of file instead of top. |
| L2 | DateFormatter created per-render | `MeetingCardView.swift:89`, `TimelineView.swift:123-130`, `MeetingDetailView.swift:202` | `DateFormatter()` created inside computed properties called on every SwiftUI render pass. Should be cached as static constants. |
| L3 | Unused enum | `InspirationPhrase.swift:15-19` | `InspirationPhrase.Timing` enum (morning, preMeeting, endOfDay) is defined but never referenced. |

---

## Built but Not Connected

These features are fully implemented but not wired into the app flow:

| Feature | Implementation | Missing Connection |
|---------|---------------|--------------------|
| RichTextEditor | `RichTextEditor.swift`, `FormattingToolbar.swift`, `RichTextHelpers.swift` | Not used in `NoteEditorView` (still plain `TextEditor`) |
| SpotlightService | `SpotlightService.swift` (index + remove) | Never called from sync or save flows |
| InspirationService | `InspirationService.swift` + `InspirationBannerView` | Never loaded in `TimelineView` |
| Note RAG indexing | `RAGService.indexNote()` | Never called from note save flow |
| Calendar sync at launch | `MeetingContextService.startBackgroundSync()` | Never called from app entry point |
| Migration plan | `PlannerMigrationPlan` in `SchemaVersion.swift` | Not passed to `ModelContainer` |
| UI test launch args | Tests use `--skip-onboarding`, `--reset-onboarding` | App never checks `ProcessInfo.arguments` |

---

## Recommended Fix Order

1. Create Xcode project or `Package.swift`
2. Implement shared service DI (`@Observable AppServices` injected via `@Environment`)
3. Fix duplicate note creation bug in `NoteEditorView.saveNote()`
4. Fix `meetingCount` inflation in `MeetingContextService.upsertMeeting()`
5. Wire up calendar sync at app launch
6. Wire up note RAG indexing on save
7. Wire up Spotlight indexing on sync/save
8. Integrate `RichTextEditor` into `NoteEditorView`
9. Load inspiration phrases in `TimelineView`
10. Add launch argument handling for UI tests
11. Fix detached task actor violation in `DataSettingsView`
12. Fix `PersonAvatarView` color determinism
13. Add accessibility labels to interactive components
14. Cache `DateFormatter` instances as statics
15. Add user-facing error handling (alerts/toasts)
16. Wire `PlannerMigrationPlan` into `ModelContainer`
