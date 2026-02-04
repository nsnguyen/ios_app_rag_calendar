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
- **Status**: [x] COMPLETED - Added double-check on both sides of relationship

### Task 1.2: Verify and Test Duplicate Note Bug (C4)
- **Location**: `NoteEditorView.swift:88-101`
- **Analysis**: Code at line 100 sets `existingNote = note` after insert, which should fix the bug
- **Action**: Write unit test to confirm fix, or verify manually
- **Status**: [x] COMPLETED - Verified in architect review, code is correct

---

## Phase 2: High Priority Integrations

### Task 2.1: Integrate RichTextEditor into NoteEditorView (H3)
- **Location**: `NoteEditorView.swift`
- **Components integrated**:
  - `RichTextEditor.swift` - UITextView wrapper
  - `FormattingToolbar.swift` - Formatting controls
  - `RichTextHelpers.swift` - Attributed string utilities
- **Status**: [x] COMPLETED - Full rich text editor now integrated

### Task 2.2: Add Spotlight Indexing for Meetings in Sync Flow
- **Location**: `MeetingContextService.swift:112`
- **Fix**: Added `spotlightService?.indexMeeting(meeting)` call
- **Status**: [x] COMPLETED - SpotlightService now passed to MeetingContextService

### Task 2.3: Wire Migration Plan to ModelContainer (M6)
- **Location**: `SharedModelContainer.swift:21`
- **Fix**: Added `migrationPlan: PlannerMigrationPlan.self` to ModelContainer init
- **Status**: [x] COMPLETED

---

## Phase 3: Medium Priority Fixes

### Task 3.1: Fix Non-Deterministic Avatar Colors (M1)
- **Location**: `PersonAvatarView.swift`
- **Fix**: Implemented DJB2 deterministic hash
- **Status**: [x] COMPLETED

### Task 3.2: Add Accessibility Labels (M3)
- **Locations**:
  - `DateChipView` (inside TimelineView.swift)
  - `MeetingCardView.swift`
  - `PersonAvatarView.swift`
  - `InspirationBannerView.swift`
  - `TagChipView.swift`
- **Status**: [x] COMPLETED - All components now have accessibility labels

### Task 3.3: Cache DateFormatter Instances (L2)
- **Locations**:
  - `MeetingCardView.swift`
  - `TimelineView.swift`
  - `MeetingDetailView.swift`
- **Status**: [x] COMPLETED - All DateFormatters now static

---

## Phase 4: Code Quality & Polish

### Task 4.1: Consolidate Test Directories
- **Current**: `Tests/`, `PlannerTests/`, `PlannerUITests/` (duplicate structure)
- **Action**: Review and consolidate or clarify which is canonical
- **Status**: [ ] SKIPPED - Low priority, works as-is

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
| -- | 1 | Task 1.1 (C3 meetingCount fix) | COMPLETED |
| -- | 1 | Task 1.2 (C4 verification) | COMPLETED |
| -- | 2 | Task 2.1 (RichTextEditor) | COMPLETED |
| -- | 2 | Task 2.2 (Spotlight meetings) | COMPLETED |
| -- | 2 | Task 2.3 (Migration plan) | COMPLETED |
| -- | 3 | Task 3.1 (Avatar colors) | COMPLETED |
| -- | 3 | Task 3.2 (Accessibility) | COMPLETED |
| -- | 3 | Task 3.3 (DateFormatter cache) | COMPLETED |
| -- | 4 | Phase 4 tasks | IN PROGRESS |

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

1. **Phase 1**: Critical bugs first (C3, verify C4) - DONE
2. **Phase 2**: High-priority integrations (RichTextEditor, Spotlight, Migration) - DONE
3. **Phase 3**: Medium fixes (Avatar colors, Accessibility, DateFormatter) - DONE
4. **Phase 4**: Polish (Docs, cleanup) - IN PROGRESS
5. **Phase 5**: Testing
