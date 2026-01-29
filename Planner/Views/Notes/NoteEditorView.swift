import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppServices.self) private var appServices

    @State private var title: String
    @State private var bodyText: String
    @State private var saveTask: Task<Void, Never>?
    @State private var existingNote: Note?

    private let meetingRecord: MeetingRecord?

    /// Create a new standalone note.
    init() {
        self._existingNote = State(initialValue: nil)
        self.meetingRecord = nil
        self._title = State(initialValue: "")
        self._bodyText = State(initialValue: "")
    }

    /// Edit an existing note.
    init(note: Note) {
        self._existingNote = State(initialValue: note)
        self.meetingRecord = note.meetingRecord
        self._title = State(initialValue: note.title)
        self._bodyText = State(initialValue: note.plainText)
    }

    /// Create a new note linked to a meeting.
    init(meetingRecord: MeetingRecord) {
        self._existingNote = State(initialValue: nil)
        self.meetingRecord = meetingRecord
        self._title = State(initialValue: "")
        self._bodyText = State(initialValue: "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title field
            TextField("Title", text: $title)
                .font(theme.typography.headingFont)
                .fontWeight(theme.typography.headingWeight)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.top, theme.spacing.lg)

            Divider()
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.sm)

            // Body text (plain TextEditor in Phase 3, replaced by RichTextEditor in Phase 4)
            TextEditor(text: $bodyText)
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, theme.spacing.md)
        }
        .background(theme.colors.background)
        .navigationTitle(existingNote == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    saveNote()
                    dismiss()
                }
            }
        }
        .onChange(of: title) { debouncedSave() }
        .onChange(of: bodyText) { debouncedSave() }
    }

    // MARK: - Save

    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            saveNote()
        }
    }

    private func saveNote() {
        if let existingNote {
            existingNote.title = title
            existingNote.plainText = bodyText
            existingNote.updatedAt = Date()
        } else {
            let note = Note(
                title: title,
                plainText: bodyText,
                meetingRecord: meetingRecord
            )
            modelContext.insert(note)
            existingNote = note
        }
        try? modelContext.save()

        // Index for search
        if let note = existingNote {
            appServices.ragService.indexNote(note, context: modelContext)
            appServices.spotlightService.indexNote(note)
        }
    }
}
