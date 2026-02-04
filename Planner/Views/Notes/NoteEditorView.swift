import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(AppServices.self) private var appServices

    @State private var title: String
    @State private var attributedText: NSAttributedString
    @State private var plainText: String
    @State private var saveTask: Task<Void, Never>?
    @State private var existingNote: Note?

    private let meetingRecord: MeetingRecord?

    /// Create a new standalone note.
    init() {
        self._existingNote = State(initialValue: nil)
        self.meetingRecord = nil
        self._title = State(initialValue: "")
        self._attributedText = State(initialValue: NSAttributedString(string: ""))
        self._plainText = State(initialValue: "")
    }

    /// Edit an existing note.
    init(note: Note) {
        self._existingNote = State(initialValue: note)
        self.meetingRecord = note.meetingRecord
        self._title = State(initialValue: note.title)
        self._plainText = State(initialValue: note.plainText)

        // Restore rich text from Data, or create from plain text
        if let data = note.richTextData,
           let restored = NSAttributedString.unarchived(from: data) {
            self._attributedText = State(initialValue: restored)
        } else {
            self._attributedText = State(initialValue: NSAttributedString(string: note.plainText))
        }
    }

    /// Create a new note linked to a meeting.
    init(meetingRecord: MeetingRecord) {
        self._existingNote = State(initialValue: nil)
        self.meetingRecord = meetingRecord
        self._title = State(initialValue: "")
        self._attributedText = State(initialValue: NSAttributedString(string: ""))
        self._plainText = State(initialValue: "")
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

            // Rich text editor with formatting toolbar
            RichTextEditor(
                attributedText: $attributedText,
                plainText: $plainText,
                onTextChange: { debouncedSave() }
            )
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
        // Archive attributed text to Data for persistence
        let richTextData = attributedText.archived()

        if let existingNote {
            existingNote.title = title
            existingNote.plainText = plainText
            existingNote.richTextData = richTextData
            existingNote.updatedAt = Date()
        } else {
            let note = Note(
                title: title,
                plainText: plainText,
                richTextData: richTextData,
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
