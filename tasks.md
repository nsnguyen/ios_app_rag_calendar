# Project Tasks - iOS Planner App Completion

**Created**: 2026-02-03
**Branch**: nathan/finish-mvp
**Status**: In Progress

---

## Overview

Based on the Architect Review, the codebase is ~65% complete. Many issues from the original code-review.md have been fixed. This document outlines the remaining work organized by phase.

---

## Phase 1: Critical Bug Fixes

### Task 1.1: Fix meetingCount Inflation Bug (C3)
- **Location**: `MeetingContextService.swift:105-108`
- **Problem**: `person.meetingCount += 1` may run on every sync pass
- **Fix**: Only increment when person is newly added to a meeting, not when re-syncing
- **Status**: [ ] Not Started

### Task 1.2: Verify and Test Duplicate Note Bug (C4)
- **Location**: `NoteEditorView.swift:88-101`
- **Analysis**: Code at line 100 sets `existingNote = note` after insert, which should fix the bug
- **Action**: Write unit test to confirm fix, or verify manually
- **Status**: [ ] Not Started

---

## Phase 2: High Priority Integrations

### Task 2.1: Integrate RichTextEditor into NoteEditorView (H3)
- **Location**: `NoteEditorView.swift`
- **Components to integrate**:
  - `RichTextEditor.swift` - UITextView wrapper
  - `FormattingToolbar.swift` - Formatting controls
  - `RichTextHelpers.swift` - Attributed string utilities
- **Changes needed**:
  1. Replace `TextEditor(text: $bodyText)` with `RichTextEditor`
  2. Add `@State` for attributed string
  3. Convert between `NSAttributedString` and `Data` for storage
  4. Update save logic to extract plain text for RAG indexing
- **Status**: [ ] Not Started

### Task 2.2: Add Spotlight Indexing for Meetings in Sync Flow
- **Location**: `MeetingContextService.swift:112`
- **Problem**: `ragService.indexMeetingRecord()` is called but not `spotlightService.indexMeeting()`
- **Fix**: Add Spotlight indexing call after RAG indexing in sync flow
- **Requires**: Pass `spotlightService` to `MeetingContextService` or use `AppServices`
- **Status**: [ ] Not Started

### Task 2.3: Wire Migration Plan to ModelContainer (M6)
- **Location**: `SharedModelContainer.swift:21`
- **Fix**: Add `migrationPlan: PlannerMigrationPlan.self` to ModelContainer initialization
- **Status**: [ ] Not Started

---

## Phase 3: Medium Priority Fixes

### Task 3.1: Fix Non-Deterministic Avatar Colors (M1)
- **Location**: `PersonAvatarView.swift`
- **Problem**: `String.hashValue` is randomized per process
- **Fix**: Implement deterministic hash (DJB2 or character-sum)
- **Status**: [ ] Not Started

### Task 3.2: Add Accessibility Labels (M3)
- **Locations**:
  - `DateChipView` (inside TimelineView.swift)
  - `MeetingCardView.swift`
  - `PersonAvatarView.swift`
  - `InspirationBannerView.swift`
  - `TagChipView.swift`
- **Fix**: Add `.accessibilityLabel()` modifiers to interactive components
- **Status**: [ ] Not Started

### Task 3.3: Cache DateFormatter Instances (L2)
- **Locations**:
  - `MeetingCardView.swift:89`
  - `TimelineView.swift:123-130`
  - `MeetingDetailView.swift:202`
- **Fix**: Create static DateFormatter instances instead of creating per-render
- **Status**: [ ] Not Started

---

## Phase 4: Code Quality & Polish

### Task 4.1: Consolidate Test Directories
- **Current**: `Tests/`, `PlannerTests/`, `PlannerUITests/` (duplicate structure)
- **Action**: Review and consolidate or clarify which is canonical
- **Status**: [ ] Not Started

### Task 4.2: Update Architecture Documentation
- **Location**: `docs/architecture.md`
- **Fix**: Update `Sources/` references to `Planner/` to match actual structure
- **Status**: [ ] Not Started

### Task 4.3: Remove Unused Enum (L3)
- **Location**: `InspirationPhrase.swift:15-19`
- **Problem**: `InspirationPhrase.Timing` enum is never used
- **Fix**: Remove or implement usage
- **Status**: [ ] Not Started

### Task 4.4: Fix Import Order (L1)
- **Location**: `ExtensionTests.swift:110`
- **Fix**: Move `import SwiftUI` to top of file
- **Status**: [ ] Not Started

---

## Phase 5: Testing & Validation

### Task 5.1: Run Full Test Suite
- **Action**: Execute all unit and UI tests
- **Command**: `xcodebuild test -project Planner.xcodeproj -scheme Planner -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Status**: [ ] Not Started

### Task 5.2: Manual QA Pass
- **Checklist**:
  - [ ] Calendar sync works
  - [ ] Notes save and persist
  - [ ] RAG search returns relevant results
  - [ ] Inspiration banner shows personalized content
  - [ ] Theme switching works
  - [ ] Navigation is smooth
  - [ ] Onboarding flow completes
- **Status**: [ ] Not Started

---

## Progress Log

| Time | Phase | Task | Status |
|------|-------|------|--------|
| -- | 1 | Architect Review | COMPLETED |
| -- | 2 | Project Planning | COMPLETED |
| -- | -- | Implementation Start | PENDING |

---

## Token Management Notes

If token limits are approached during implementation:
1. Stop at the current task boundary
2. Update this file with progress
3. Commit changes
4. Note the pause point below

**Last Pause Point**: None

---

## Implementation Order

1. **Phase 1**: Critical bugs first (C3, verify C4)
2. **Phase 2**: High-priority integrations (RichTextEditor, Spotlight, Migration)
3. **Phase 3**: Medium fixes (Avatar colors, Accessibility, DateFormatter)
4. **Phase 4**: Polish (Docs, cleanup)
5. **Phase 5**: Testing
