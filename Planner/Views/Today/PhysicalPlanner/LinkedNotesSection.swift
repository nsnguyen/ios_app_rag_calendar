import SwiftUI
import SwiftData

struct LinkedNotesSection: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    let date: Date
    let onNoteTap: (Note) -> Void
    let onAddNote: () -> Void

    @Query private var allNotes: [Note]

    init(date: Date, onNoteTap: @escaping (Note) -> Void, onAddNote: @escaping () -> Void) {
        self.date = date
        self.onNoteTap = onNoteTap
        self.onAddNote = onAddNote
        // Query notes created on this date
        let start = date.startOfDay
        let end = date.endOfDay
        _allNotes = Query(
            filter: #Predicate<Note> { note in
                note.createdAt >= start && note.createdAt <= end
            },
            sort: [SortDescriptor(\Note.createdAt, order: .reverse)]
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header
            HStack {
                Label("Notes", systemImage: "note.text")
                    .font(theme.typography.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.textSecondary)

                Spacer()

                Button(action: onAddNote) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(theme.colors.accent)
                }
            }

            if allNotes.isEmpty {
                Text("No notes for this day")
                    .font(.caption2)
                    .foregroundStyle(theme.colors.textTertiary)
                    .italic()
                    .padding(.vertical, theme.spacing.xs)
            } else {
                VStack(spacing: theme.spacing.xs) {
                    ForEach(allNotes.prefix(3)) { note in
                        Button {
                            onNoteTap(note)
                        } label: {
                            NoteRowView(note: note)
                        }
                        .buttonStyle(.plain)
                    }

                    if allNotes.count > 3 {
                        Text("+\(allNotes.count - 3) more")
                            .font(.caption2)
                            .foregroundStyle(theme.colors.textTertiary)
                    }
                }
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius / 2, style: .continuous))
    }
}

// MARK: - Note Row View

private struct NoteRowView: View {
    @Environment(\.theme) private var theme
    let note: Note

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            Circle()
                .fill(theme.colors.accent.opacity(0.3))
                .frame(width: 6, height: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)

                if !note.plainText.isEmpty {
                    Text(note.plainText)
                        .font(.caption2)
                        .foregroundStyle(theme.colors.textTertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(theme.colors.textTertiary)
        }
        .padding(.vertical, theme.spacing.xxs)
    }
}
