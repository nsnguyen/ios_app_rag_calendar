import AppIntents
import Foundation
import SwiftData

struct SearchNotesIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Notes"
    static var description: IntentDescription = "Search your notes using natural language."

    @Parameter(title: "Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search notes for \(\.$query)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(SharedModelContainer.shared)
        let embeddingService = EmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)
        let results = ragService.search(query: query, topK: 3, context: context)
            .filter { $0.sourceType == "note" }

        if results.isEmpty {
            return .result(
                value: "No results found.",
                dialog: "I couldn't find any notes matching your query."
            )
        }

        let response = results.map(\.chunkText).joined(separator: "\n")
        return .result(
            value: response,
            dialog: IntentDialog(stringLiteral: response)
        )
    }
}
