import AppIntents
import Foundation
import SwiftData

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Note"
    static var description: IntentDescription = "Create a new note in Planner."

    @Parameter(title: "Title")
    var title: String

    @Parameter(title: "Content")
    var content: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Create a note titled \(\.$title)") {
            \.$content
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(SharedModelContainer.shared)
        let note = Note(
            title: title,
            plainText: content ?? ""
        )
        context.insert(note)
        try context.save()

        return .result(
            dialog: "Created a note titled \"\(title)\"."
        )
    }
}
