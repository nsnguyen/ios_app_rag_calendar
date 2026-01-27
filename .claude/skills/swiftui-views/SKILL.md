---
name: swiftui-views
description: Build the SwiftUI view layer for the iOS 18+ planner app following Apple HIG, including navigation, data-driven lists, search, accessibility, and reusable components. This skill should be used when creating or modifying any SwiftUI views, navigation structure, or UI components.
---

# SwiftUI Views

## Overview

Implement the full SwiftUI view hierarchy for the planner app. All views follow Apple Human Interface Guidelines for an Apple-native look and feel. Views are data-driven via SwiftData `@Query` and `@Environment(\.modelContext)`.

## App Navigation Structure

Use a `TabView` as the root with four tabs:

```swift
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Today", systemImage: "calendar") {
                NavigationStack {
                    TimelineView()
                }
            }
            Tab("Notes", systemImage: "note.text") {
                NavigationStack {
                    NotesListView()
                }
            }
            Tab("Search", systemImage: "magnifyingglass") {
                NavigationStack {
                    SearchView()
                }
            }
            Tab("People", systemImage: "person.2") {
                NavigationStack {
                    PeopleView()
                }
            }
        }
    }
}
```

Each tab has its own `NavigationStack` for independent navigation histories.

## Key Views

### TimelineView (Today Tab)

```swift
struct TimelineView: View {
    @Query(
        filter: #Predicate<MeetingRecord> { meeting in
            // Filter applied dynamically
            true
        },
        sort: \MeetingRecord.startDate
    )
    private var meetings: [MeetingRecord]

    @State private var selectedDate = Date()

    var body: some View {
        List {
            if filteredMeetings.isEmpty {
                ContentUnavailableView(
                    "No Meetings",
                    systemImage: "calendar.badge.checkmark",
                    description: Text("Your calendar is clear for today.")
                )
            } else {
                ForEach(filteredMeetings) { meeting in
                    NavigationLink(value: meeting) {
                        MeetingCardView(meeting: meeting)
                    }
                }
            }
        }
        .navigationTitle("Today")
        .navigationDestination(for: MeetingRecord.self) { meeting in
            MeetingDetailView(meeting: meeting)
        }
    }
}
```

### MeetingCardView (Reusable Component)

```swift
struct MeetingCardView: View {
    let meeting: MeetingRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                Spacer()
                Text(meeting.startDate, style: .time)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let purpose = meeting.purpose {
                Text(purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !meeting.attendees.isEmpty {
                HStack(spacing: -8) {
                    ForEach(meeting.attendees.prefix(3)) { person in
                        PersonAvatarView(person: person, size: 24)
                    }
                    if meeting.attendees.count > 3 {
                        Text("+\(meeting.attendees.count - 3)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if !meeting.tags.isEmpty {
                HStack {
                    ForEach(meeting.tags) { tag in
                        TagChipView(tag: tag)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(meeting.title), \(meeting.startDate.formatted(date: .omitted, time: .shortened))")
    }
}
```

### NotesListView

```swift
struct NotesListView: View {
    @Query(sort: \Note.updatedAt, order: .reverse)
    private var notes: [Note]
    @State private var searchText = ""

    var body: some View {
        List {
            ForEach(filteredNotes) { note in
                NavigationLink(value: note) {
                    NotePreviewRow(note: note)
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Note", systemImage: "plus") {
                    createNote()
                }
            }
        }
        .navigationDestination(for: Note.self) { note in
            NoteEditorView(note: note)
        }
        .overlay {
            if filteredNotes.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if notes.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "note.text",
                    description: Text("Tap + to create your first note.")
                )
            }
        }
    }
}
```

### SearchView (RAG-Powered)

```swift
struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        List {
            if isSearching {
                HStack {
                    ProgressView()
                    Text("Searching...")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(results, id: \.embeddingRecord.id) { result in
                SearchResultRow(result: result)
            }
        }
        .navigationTitle("Search")
        .searchable(text: $query, prompt: "Ask about your meetings...")
        .onSubmit(of: .search) {
            performSearch()
        }
        .overlay {
            if results.isEmpty && !query.isEmpty && !isSearching {
                ContentUnavailableView.search(text: query)
            } else if query.isEmpty {
                ContentUnavailableView(
                    "Semantic Search",
                    systemImage: "sparkle.magnifyingglass",
                    description: Text("Ask questions like \"What did I discuss with Sarah last week?\"")
                )
            }
        }
    }
}
```

## Reusable Components

### TagChipView

```swift
struct TagChipView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(hex: tag.color).opacity(0.15))
            .foregroundStyle(Color(hex: tag.color))
            .clipShape(Capsule())
    }
}
```

### PersonAvatarView

```swift
struct PersonAvatarView: View {
    let person: Person
    var size: CGFloat = 32

    var body: some View {
        Text(person.name.prefix(1).uppercased())
            .font(.system(size: size * 0.45, weight: .medium))
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.15))
            .foregroundStyle(.accentColor)
            .clipShape(Circle())
            .accessibilityLabel(person.name)
    }
}
```

## SwiftUI Patterns

### Data Access

- Use `@Query` in views for declarative data fetching
- Use `@Environment(\.modelContext)` for writes (insert, delete, save)
- In non-view code (services), use `ModelContext(modelContainer)` directly

### State Management

- `@State` for view-local state
- `@Observable` classes for shared services (injected via `.environment()`)
- Avoid `@ObservedObject` / `ObservableObject` — use `@Observable` macro (iOS 17+)

### Empty/Loading/Error States

Always handle all three:
- **Empty**: Use `ContentUnavailableView` with an SF Symbol, title, and description
- **Loading**: Use `ProgressView()` with a label
- **Error**: Use `.alert()` for recoverable errors

### Accessibility Checklist

- `accessibilityLabel` on all custom views that combine information
- `accessibilityHint` for non-obvious interactions
- Avoid hard-coded font sizes — always use text styles
- Test with Dynamic Type at largest accessibility size
- Support VoiceOver navigation order via `accessibilitySortPriority`
- Use `.accessibilityAddTraits(.isButton)` on tappable non-Button views

### Context Menus and Swipe Actions

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        deleteNote(note)
    } label: {
        Label("Delete", systemImage: "trash")
    }
}
.contextMenu {
    Button("Share", systemImage: "square.and.arrow.up") { share(note) }
    Button("Add Tag", systemImage: "tag") { showTagPicker = true }
    Divider()
    Button("Delete", systemImage: "trash", role: .destructive) { deleteNote(note) }
}
```
