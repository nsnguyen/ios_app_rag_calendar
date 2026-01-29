import AppIntents
import Foundation
import SwiftData

struct NoteEntity: AppEntity {
    static var defaultQuery = NoteEntityQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Note")

    var id: String
    var title: String
    var preview: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title.isEmpty ? "Untitled" : title)",
            subtitle: "\(preview)"
        )
    }

    init(from note: Note) {
        self.id = "\(note.persistentModelID.hashValue)"
        self.title = note.title
        self.preview = String(note.plainText.prefix(100))
    }
}

struct NoteEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [NoteEntity] {
        let context = ModelContext(SharedModelContainer.shared)
        let descriptor = FetchDescriptor<Note>()
        let allNotes = (try? context.fetch(descriptor)) ?? []
        return identifiers.compactMap { id in
            allNotes.first { "\($0.persistentModelID.hashValue)" == id }
                .map { NoteEntity(from: $0) }
        }
    }

    func suggestedEntities() async throws -> [NoteEntity] {
        let context = ModelContext(SharedModelContainer.shared)
        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        let notes = (try? context.fetch(descriptor)) ?? []
        return notes.map { NoteEntity(from: $0) }
    }
}
