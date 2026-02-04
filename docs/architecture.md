# Planner -- Architecture Document

iOS 18+ SwiftUI daily planner with on-device RAG AI memory. iPhone only.

**Core thesis**: No daily planner has long-term AI memory. Motion, Sunsama, and Structured plan your day but can't answer "what did I do in August?". Notion and Mem can search notes but aren't focused daily planners. Planner fills this gap: your calendar events are already on the timeline, you add notes throughout the day, and an on-device AI quietly indexes everything -- so months later you can ask natural language questions about your own history. All private. All offline. Zero server costs.

---

## On-Device RAG Pipeline (Core Differentiator)

The RAG (Retrieval-Augmented Generation) system is the product's competitive moat. Everything runs on-device using Apple's NaturalLanguage framework -- no cloud API, no OpenAI bills, no data leaving the phone.

### Why On-Device

| Concern | Cloud RAG | Our On-Device RAG |
|---------|-----------|-------------------|
| Privacy | User data sent to servers | Data never leaves the phone |
| Cost | Per-query API fees (OpenAI, etc.) | Zero marginal cost -- Apple's NLEmbedding is free |
| Offline | Requires internet | Works on airplane mode |
| Latency | Network round-trip | Instant local vector search |
| Lifetime pricing | Unsustainable at scale | Viable because no server costs |

This architecture enables the lifetime purchase option ($60-80) that cloud-dependent competitors like Motion ($29/mo) and Sunsama ($20/mo) can't offer.

### What Gets Indexed

Every piece of user data flows into the embedding index automatically:

| Source | Indexed Fields | Trigger |
|--------|---------------|---------|
| Calendar events | Title, date, attendees, location | Calendar sync (auto, -30 to +7 days) |
| Meeting metadata | Purpose, outcomes, action items | User edits meeting detail |
| Notes | Full plain text (paragraph-chunked) | 1.5s debounce after edit |
| People | Name, email, meeting history | Derived from calendar attendees |

Over weeks and months, the index accumulates a searchable history of the user's professional life.

### Embedding Generation

- **Framework**: `NaturalLanguage` -- `NLEmbedding.sentenceEmbedding(for: .english)`
- **Dimension**: 512 (system-bundled model, no download)
- **Storage**: `EmbeddingRecord` SwiftData model with `vectorData: Data` ([Double] encoded via `withUnsafeBufferPointer` for zero-copy roundtrip)

### Chunking Strategy

Content is split into semantically meaningful chunks before embedding:

**Meetings** (up to 6 chunks per meeting):
1. Title + formatted date
2. Attendee names
3. Purpose
4. Outcomes
5. Action items
6. Location

**Notes** (variable chunks):
- Split by paragraph (`\n\n`)
- Paragraphs >200 words split further by sentence
- Minimum 5-word threshold (filters noise)
- Target: 50-200 words per chunk for optimal embedding quality

### Similarity Search

- **Algorithm**: Cosine similarity via `vDSP_dotprD` (Accelerate framework -- hardware-optimized SIMD)
- **Threshold**: 0.3 minimum similarity score (filters irrelevant results)
- **Default top-K**: 5 results
- **Process**: Query text -> NLEmbedding vector -> compare against all stored EmbeddingRecords -> rank by score -> resolve back to source MeetingRecord or Note

### Example Queries the System Handles

These are the kinds of natural language questions users can ask in the Search tab or via Siri:

- "What did I work on in August?"
- "When did I last discuss the vendor contract?"
- "What meetings did I have with Sarah?"
- "What were the action items from the sprint planning?"
- "What happened in the Q3 budget meeting?"
- "Notes about the product redesign"

### How RAG Connects to Other Features

| Feature | RAG Role |
|---------|----------|
| **Search tab** | Primary query interface -- user types natural language, gets ranked results |
| **Meeting briefs** | RAG retrieves context from previous meetings with the same attendees |
| **Siri intents** | `QueryMeetingIntent` and `SearchNotesIntent` route through RAGService |
| **Spotlight** | CoreSpotlight indexes the same content for system-wide search |
| **Inspiration phrases** | SummarizationService uses meeting/note counts (not RAG directly, but same data) |
| **People view** | Relationship summaries draw from meeting history indexed by RAG |

### Accumulation Value

The RAG index becomes more valuable over time. A user's first week has a few meetings. After 6 months, they have thousands of chunks spanning hundreds of meetings and notes. This creates a switching cost -- no other app has their indexed professional history. This is the retention moat.

### Implementation Files

| File | Role |
|------|------|
| `EmbeddingService.swift` | NLEmbedding wrapper, vector generation |
| `RAGService.swift` | Chunking, indexing, cosine similarity search |
| `EmbeddingRecord.swift` | SwiftData model for vector storage |
| `MeetingContextService.swift` | Orchestrates sync -> chunk -> embed -> store pipeline |
| `Array+Data.swift` | [Double] <-> Data encoding for vector persistence |
| `SearchView.swift` | User-facing query interface |
| `QueryMeetingIntent.swift` | Siri voice query -> RAG search |
| `SearchNotesIntent.swift` | Siri note search -> RAG search |

---

## Directory Structure

```
Planner/
├── App/                    # Entry point, container, config files
│   ├── PlannerApp.swift
│   ├── ContentView.swift
│   ├── SharedModelContainer.swift
│   ├── Info.plist
│   ├── Planner.entitlements
│   └── PrivacyInfo.xcprivacy
├── Models/                 # SwiftData @Model classes
│   ├── MeetingRecord.swift
│   ├── Note.swift
│   ├── Person.swift
│   ├── EmbeddingRecord.swift
│   ├── Tag.swift
│   └── SchemaVersion.swift
├── Theme/                  # Design system
│   ├── AppTheme.swift
│   ├── ThemeConfiguration.swift
│   ├── ThemeManager.swift
│   ├── ThemeEnvironment.swift
│   └── ThemeModifiers.swift
├── Services/               # Business logic (protocol-based)
│   ├── AppServices.swift   # DI container for all services
│   ├── CalendarServiceProtocol.swift
│   ├── CalendarService.swift
│   ├── EmbeddingService.swift
│   ├── RAGService.swift
│   ├── SummarizationService.swift
│   ├── MeetingContextService.swift
│   ├── SpotlightService.swift
│   └── InspirationService.swift
├── Views/
│   ├── Today/              # Timeline + meeting cards
│   ├── Notes/              # Notes list + editor
│   ├── Search/             # RAG-powered semantic search
│   ├── People/             # Contact relationship tracking
│   ├── Settings/           # Theme picker, permissions, data
│   ├── Onboarding/         # First-launch flow
│   ├── Components/         # Shared UI components
│   └── RichText/           # UITextView-based rich text editor
├── Intents/                # App Intents for Siri & Shortcuts
├── Extensions/             # Color+Hex, Date+Helpers, Array+Data, etc.
└── Supporting/             # DTOs and value types

Tests/
├── Mocks/                  # Mock implementations of service protocols
├── Fixtures/               # Factory methods + vector test helpers
├── Models/                 # SwiftData CRUD, cascade delete, relationship tests
├── Services/               # RAG indexing, cosine similarity, sync pipeline tests
├── Theme/                  # Theme persistence, spacing scale, extension tests
└── Views/                  # XCUITest: onboarding, tabs, notes, theme, search
```

---

## Data Model

```
MeetingRecord ──┬── notes: [Note]              (cascade delete)
                ├── attendees: [Person]         (many-to-many)
                ├── embeddings: [EmbeddingRecord] (cascade delete)
                └── tags: [Tag]                 (many-to-many)

Note ───────────┬── meetingRecord: MeetingRecord? (optional inverse)
                ├── embeddings: [EmbeddingRecord] (cascade delete)
                └── tags: [Tag]                 (many-to-many)

Person ─────────── meetings: [MeetingRecord]    (inverse)

EmbeddingRecord ┬── meetingRecord: MeetingRecord? (one or the other)
                └── note: Note?

Tag ────────────┬── meetingRecords: [MeetingRecord]
                └── notes: [Note]
```

**Unique constraints**: `MeetingRecord.eventIdentifier`, `Person.email`, `Tag.name`

**Schema versioning**: `SchemaVersions.V1` (1.0.0) with `PlannerMigrationPlan` (empty stages, ready for future migrations).

---

## Theme System

Four complete design languages, not just color swaps:

| Theme | Typography | Feel | Icon Mode |
|-------|-----------|------|-----------|
| **Calm** | Charter serif + Seravek | Luxury journal | `.hierarchical` |
| **Bold** | SF Rounded + SF Pro | Power tool (dark-mode only) | `.palette` |
| **Warm** | Georgia + Seravek | Cozy notebook | `.multicolor` |
| **Minimal** | SF Pro (system) | Precision instrument | `.monochrome` |

Each `ThemeConfiguration` bundles:
- `ThemeColors` -- 13 semantic tokens (primary, secondary, accent, background, surface, card, 3x text, border, meetingCard, noteHighlight, tagBackground)
- `ThemeTypography` -- display/heading/body/caption/mono fonts + weights + letter spacing
- `ThemeSpacing` -- 8-point scale (xxs through xxxl)
- `ThemeShapes` -- card/button/chip/sheet/input corner radii
- `ThemeShadows` -- card/elevated/subtle with theme-tinted colors
- `ThemeMotion` -- default animation, spring params, stagger delay, transition style

**Storage**: `UserDefaults` (not SwiftData) -- must be available before `ModelContainer` init.

**Injection**: Custom `EnvironmentKey` at `\.theme`. All views read `@Environment(\.theme)`.

---

## Service Layer

All services are protocol-based for testability via mock injection.

### CalendarService
- iOS 17+ `requestFullAccessToEvents()`
- Extracts attendee emails from `participant.url` (mailto: scheme)
- Returns `CalendarEventData` boundary DTOs

### EmbeddingService
- `NLEmbedding.sentenceEmbedding(for: .english)`
- 512-dimensional vectors
- System-bundled model, no download required

### RAGService
- **Meeting chunking** (6 chunks): title/date, attendees, purpose, outcomes, action items, location
- **Note chunking**: paragraph splitting, sentence fallback for >200 word paragraphs, minimum 5-word filter
- **Cosine similarity**: `vDSP_dotprD` via Accelerate framework
- **Search**: threshold 0.3, default top-K 5

### SummarizationService
- `@available(iOS 26, *)` Foundation Models via `LanguageModelSession`
- Fallback: deterministic template-based summaries on iOS 18-25
- Methods: meeting summary, action item extraction, meeting brief, relationship summary, weekly recap, inspiration phrase

### MeetingContextService
- **Orchestrator** for all other services
- Sync window: -30 to +7 days
- Listens to `NSNotification.Name.EKEventStoreChanged`
- Background indexing via `Task.detached(priority: .utility)`

### SpotlightService
- `CSSearchableItem` with domain identifiers (`com.planner.meetings`, `com.planner.notes`)
- Identifier format: `meeting:{eventIdentifier}`, `note:{hashValue}`
- 1-year expiration

### InspirationService
- Delegates to `SummarizationService`
- Configurable tone: warm, direct, reflective
- Falls back to hardcoded phrases

---

## Data Flow Pipelines

### Calendar Sync
```
EKEvent[] → CalendarEventData[] → upsert MeetingRecord
  → upsert Person (attendees) → chunk text
  → generate embeddings → store EmbeddingRecord
  → index CoreSpotlight
```

### Note Save
```
UITextView edit → 1.5s debounce → archive rich text
  → extract plainText → re-chunk → re-embed
  → index CoreSpotlight
```

### RAG Query
```
question → NLEmbedding vector → fetch all EmbeddingRecords
  → cosine similarity (Accelerate) → top-K above 0.3
  → resolve source MeetingRecord/Note → optional summarization
```

---

## Navigation Structure

```
ContentView
├── [if !hasCompletedOnboarding] OnboardingView
│   └── Welcome → Theme Selection → Calendar Permission → Siri
└── [if hasCompletedOnboarding] TabView
    ├── Today: NavigationStack → TimelineView → MeetingDetailView
    ├── Notes: NavigationStack → NotesListView → NoteEditorView
    ├── Search: NavigationStack → SearchView
    ├── People: NavigationStack → PeopleView → PersonDetailView → MeetingDetailView
    └── Settings (sheet from toolbar gear)
        ├── ThemePickerView
        ├── InspirationSettingsView
        ├── PermissionsSettingsView
        └── DataSettingsView
```

---

## App Intents (Siri & Shortcuts)

| Intent | Trigger Phrases | Behavior |
|--------|----------------|----------|
| `ShowTodayIntent` | "What meetings do I have in Planner" | Opens app, reports count |
| `QueryMeetingIntent` | "Search meetings in Planner" | RAG search, returns top-3 dialog |
| `SearchNotesIntent` | "Search notes in Planner" | RAG search filtered to notes |
| `CreateNoteIntent` | "Create a note in Planner" | Inserts via SharedModelContainer |

All intents use `SharedModelContainer.shared` (not `@Environment`) for process isolation.

---

## Key Architectural Decisions

1. **Theme in UserDefaults, not SwiftData** -- Available before `ModelContainer` init, simple scalar.
2. **Protocol-based services** -- Every service has a protocol; mocks injected in tests.
3. **Bold theme is dark-mode only** -- Matches its design intent (dark navy + electric indigo).
4. **Minimal theme uses system adaptive colors** -- Auto light/dark via `Color(.systemBackground)`.
5. **`sourceType` is String not enum** -- Avoids SwiftData schema migration when adding new types.
6. **`SummarizationService` is `@available(iOS 26, *)`** -- App compiles on iOS 18+ without it.
7. **All fonts are system-bundled** -- Charter, Georgia, Seravek, SF Pro/Rounded. No custom font embedding.
8. **`SharedModelContainer`** -- Static container for App Intents process isolation.
9. **Rich text via UIViewRepresentable** -- `UITextView` with `allowsEditingTextAttributes`, bridged to SwiftUI with `inputAccessoryView` toolbar.
10. **Vector storage as `Data`** -- `[Double] <-> Data` via `withUnsafeBufferPointer` for zero-copy roundtrip.

---

## Testing Strategy

- **4 mocks**: `MockCalendarService`, `MockEmbeddingService`, `MockRAGService`, `MockSummarizationService`
- **2 fixtures**: `TestFixtures` (factory methods for all models), `VectorTestHelpers` (unit/orthogonal/opposite vectors)
- **13 unit test files**: Model CRUD + cascade deletes, RAG cosine similarity + indexing + search ranking, embedding service, summarization, meeting context sync/timeline/query, inspiration, spotlight, theme persistence + spacing scale, extensions (Color hex, Date helpers, Array+Data roundtrip, plaintext extraction)
- **5 UI test files**: Onboarding flow, tab navigation, note creation, theme picker, search

All unit tests use Swift Testing (`@Test`, `#expect`). UI tests use XCTest (`XCUIApplication`). In-memory `ModelContainer` for all data tests.

---

## File Count

| Phase | Files |
|-------|-------|
| P1: Scaffold + Models + Theme | 28 |
| P2: Services | 8 |
| P3: Core Views | 19 |
| P4: Rich Text Editor | 3 |
| P5: Apple Intelligence | 7 |
| P6: Testing | 24 |
| **Total** | **89** |

---

## Build Requirements

- Xcode 16+
- iOS 18.0 deployment target
- Swift 6
- Frameworks: SwiftUI, SwiftData, EventKit, NaturalLanguage, Accelerate, CoreSpotlight, AppIntents
