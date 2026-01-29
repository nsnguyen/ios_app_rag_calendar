import SwiftUI
import SwiftData

struct NotesListView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var searchText = ""
    @State private var showSettings = false

    var body: some View {
        Group {
            if filteredNotes.isEmpty && searchText.isEmpty {
                EmptyStateView(
                    title: "No Notes",
                    systemImage: "note.text",
                    description: "Create your first note to get started."
                )
            } else if filteredNotes.isEmpty {
                EmptyStateView(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    description: "No notes match \"\(searchText)\"."
                )
            } else {
                List {
                    ForEach(filteredNotes) { note in
                        NavigationLink {
                            NoteEditorView(note: note)
                        } label: {
                            NoteRowView(note: note)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
                .listStyle(.plain)
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Notes")
        .searchable(text: $searchText, prompt: "Search notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: theme.spacing.md) {
                    NavigationLink {
                        NoteEditorView()
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .symbolRenderingMode(theme.iconRenderingMode)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var filteredNotes: [Note] {
        if searchText.isEmpty { return notes }
        return notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.plainText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func deleteNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredNotes[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Note Row

private struct NoteRowView: View {
    @Environment(\.theme) private var theme
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(theme.typography.bodyFont)
                .fontWeight(.medium)
                .foregroundStyle(theme.colors.textPrimary)

            if !note.plainText.isEmpty {
                Text(String(note.plainText.prefix(100)))
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(2)
            }

            HStack {
                Text(note.updatedAt.formatted(as: .shortDate))
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textTertiary)

                if note.meetingRecord != nil {
                    Label("Meeting", systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(theme.colors.accent)
                }

                if !note.tags.isEmpty {
                    ForEach(note.tags.prefix(2)) { tag in
                        Text(tag.name)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.colors.tagBackground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}
