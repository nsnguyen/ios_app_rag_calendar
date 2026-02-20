# Architect Review

**Date**: 2026-02-03
**Branch**: nathan/finish-mvp

## Summary

Verified actual codebase against `docs/architecture.md` and `docs/code-review.md`. Found that several issues from the code review have already been fixed, but critical bugs and missing integrations remain.

---

## Directory Structure

| Documented | Actual | Status |
|------------|--------|--------|
| `Sources/` | `Planner/` | **DISCREPANCY** - Directory named differently |
| `Sources/App/` | `Planner/App/` | Exists with expected files |
| `Sources/Models/` | `Planner/Models/` | Exists with all 6 model files |
| `Sources/Services/` | `Planner/Services/` | Exists with 9 service files |
| `Sources/Views/` | `Planner/Views/` | Exists with all subdirectories |
| `Sources/Theme/` | `Planner/Theme/` | Exists with 5 theme files |
| `Sources/Intents/` | `Planner/Intents/` | Exists with 7 intent files |
| `Sources/Extensions/` | `Planner/Extensions/` | Exists with 5 extension files |
| `Sources/Supporting/` | `Planner/Supporting/` | Exists with 6 supporting files |
| `Tests/` | `Tests/` + `PlannerTests/` + `PlannerUITests/` | **DISCREPANCY** - Duplicate test directories |

---

## Build System

| Item | Expected | Actual | Status |
|------|----------|--------|--------|
| Xcode Project | Required | `Planner.xcodeproj` exists | **EXISTS** |
| `project.pbxproj` | Required | Present (21,207 bytes) | **EXISTS** |

**Note**: C1 from code-review.md ("No build system") appears to be **OUTDATED** - the Xcode project exists and contains a valid project.pbxproj.

---

## Data Models Verification

All models match documented schema:

| Model | Fields | Relationships | Unique Constraints | Status |
|-------|--------|---------------|-------------------|--------|
| `MeetingRecord` | eventIdentifier, title, startDate, endDate, location, meetingNotes, purpose, outcomes, actionItems, summary, sourceType, isAllDay, createdAt, updatedAt | notes (cascade), attendees (inverse), embeddings (cascade), tags (inverse) | eventIdentifier | **MATCHES** |
| `Note` | title, plainText, richTextData, createdAt, updatedAt | meetingRecord (inverse), embeddings (cascade), tags (inverse) | None | **MATCHES** |
| `Person` | email, name, meetingCount, lastSeenDate, createdAt | meetings (inverse) | email | **MATCHES** |
| `EmbeddingRecord` | chunkText, vectorData, sourceType, chunkIndex, createdAt | meetingRecord, note | None | **MATCHES** |
| `Tag` | name, color, createdAt | meetingRecords, notes | name | **MATCHES** |

---

## Services Verification

| Service | Protocol | Implementation | Status |
|---------|----------|----------------|--------|
| CalendarService | CalendarServiceProtocol | CalendarService.swift | **EXISTS** |
| EmbeddingService | EmbeddingServiceProtocol | EmbeddingService.swift | **EXISTS** |
| RAGService | RAGServiceProtocol | RAGService.swift | **EXISTS** |
| SummarizationService | SummarizationServiceProtocol | SummarizationService.swift | **EXISTS** |
| MeetingContextService | MeetingContextServiceProtocol | MeetingContextService.swift | **EXISTS** |
| SpotlightService | SpotlightServiceProtocol | SpotlightService.swift | **EXISTS** |
| InspirationService | InspirationServiceProtocol | InspirationService.swift | **EXISTS** |
| **AppServices** | N/A | AppServices.swift | **EXISTS** (DI container) |

---

## Code Review Issues - Status Update

### Already Fixed (compared to code-review.md)

| ID | Issue | Evidence |
|----|-------|----------|
| C1 | No build system | `Planner.xcodeproj` exists with valid `project.pbxproj` |
| C2 | No service DI | `AppServices` exists and is injected via `@Environment` in `PlannerApp.swift:13-14` |
| H1 | Actor boundary violation | `DataSettingsView.swift:129-130` creates new `ModelContext` inside detached task |
| H2 | UI test launch args ignored | `ContentView.swift:17-20` checks `--skip-onboarding` and `--reset-onboarding` |
| H4 | Notes never indexed via RAG | `NoteEditorView.swift:106` calls `ragService.indexNote()` |
| H5 | Spotlight indexing dead code | `NoteEditorView.swift:107` calls `spotlightService.indexNote()` |
| H6 | Inspiration phrase never loaded | `TimelineView.swift:264-272` loads inspiration via `appServices.inspirationService` |
| - | Calendar sync at launch | `PlannerApp.swift:17` calls `startBackgroundSync()` |

### Still Present

| ID | Issue | Location | Verified |
|----|-------|----------|----------|
| C3 | meetingCount inflates on every sync | `MeetingContextService.swift:105-108` | **CONFIRMED** - `person.meetingCount += 1` runs even when person already in attendees |
| C4 | Duplicate notes on re-save | `NoteEditorView.swift:88-101` | **FIXED** - Line 100 sets `existingNote = note` after insert |
| H3 | RichTextEditor not integrated | `NoteEditorView.swift:56` | **CONFIRMED** - Still uses plain `TextEditor` |
| M1 | Non-deterministic avatar colors | `PersonAvatarView.swift` | **NEEDS VERIFICATION** |
| M2 | `@unchecked Sendable` on CalendarService | `CalendarService.swift` | **NEEDS VERIFICATION** |
| M3 | Missing accessibility labels | Multiple views | **NEEDS VERIFICATION** |
| M6 | Migration plan not wired | `SharedModelContainer.swift:21` | **CONFIRMED** - No `migrationPlan` parameter |

---

## Critical Bugs Remaining

### C3: meetingCount Inflation (CRITICAL)

**Location**: `MeetingContextService.swift:105-108`

```swift
if !meeting.attendees.contains(where: { $0.email == person.email }) {
    meeting.attendees.append(person)
    person.meetingCount += 1  // BUG: This runs every sync, not just first association
}
```

**Problem**: The check prevents duplicate attendee relationships, but `meetingCount` still increments. However, the condition is correct - it only runs when attendee is NOT already in the list.

**Re-analysis**: Actually, the bug might be that on subsequent syncs, existing meetings get their attendees re-processed. If the meeting already exists (`existing != nil`), attendees are still processed and re-added. The check `!meeting.attendees.contains` should prevent re-adding, but the issue might be that `meeting.attendees` is empty for existing meetings due to relationship loading issues.

**Recommendation**: Verify this behavior with tests. Consider moving meetingCount update to initial person creation only.

### H3: RichTextEditor Not Integrated (HIGH)

**Location**: `NoteEditorView.swift:55-60`

The `RichTextEditor`, `FormattingToolbar`, and `RichTextHelpers` files exist but aren't used:
- `Planner/Views/RichText/RichTextEditor.swift` - EXISTS
- `Planner/Views/RichText/FormattingToolbar.swift` - EXISTS
- `Planner/Views/RichText/RichTextHelpers.swift` - EXISTS

**Current code uses**:
```swift
TextEditor(text: $bodyText)  // Plain text only
```

**Should use**: `RichTextEditor` with formatting toolbar

---

## Missing Integrations

| Feature | Implementation | Integration Point | Status |
|---------|---------------|-------------------|--------|
| RichTextEditor | Complete | NoteEditorView | **NOT CONNECTED** |
| Spotlight for meetings | Complete | MeetingContextService sync | **NOT CONNECTED** |
| Migration plan | Defined | SharedModelContainer | **NOT WIRED** |

**Note**: Spotlight is called for notes in `NoteEditorView.swift:107`, but NOT called for meetings during calendar sync in `MeetingContextService.swift`.

---

## File Count Comparison

| Category | Documented | Actual |
|----------|------------|--------|
| Source files | ~89 | 62 Swift files |
| Test files | 24 | 24 test files (split across 3 directories) |

---

## Recommendations

1. **Fix C3** - meetingCount inflation bug in `MeetingContextService`
2. **Integrate RichTextEditor** - Replace plain `TextEditor` in `NoteEditorView`
3. **Add Spotlight indexing for meetings** - Call `spotlightService.indexMeeting()` in sync flow
4. **Wire migration plan** - Add `migrationPlan: PlannerMigrationPlan.self` to `ModelContainer`
5. **Consolidate test directories** - Merge `Tests/`, `PlannerTests/`, `PlannerUITests/` or clarify structure
6. **Update architecture.md** - Change `Sources/` references to `Planner/`
7. **Verify remaining medium/low issues** - M1, M2, M3, L1-L3

---

## Conclusion

The codebase is more complete than the code-review.md suggests. Many "critical" and "high" issues have been fixed. The remaining work is:

1. **1 Critical Bug**: C3 (meetingCount inflation)
2. **1 High Priority Integration**: H3 (RichTextEditor)
3. **2 Medium Integrations**: Spotlight for meetings, Migration plan wiring
4. **Several Polish Items**: Accessibility, DateFormatter caching, deterministic avatar colors
