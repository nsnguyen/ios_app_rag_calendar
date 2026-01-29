import AppIntents
import Foundation
import SwiftData

struct QueryMeetingIntent: AppIntent {
    static var title: LocalizedStringResource = "Query Meetings"
    static var description: IntentDescription = "Search your meetings using natural language."

    @Parameter(title: "Question")
    var question: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search meetings for \(\.$question)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(SharedModelContainer.shared)
        let embeddingService = EmbeddingService()
        let ragService = RAGService(embeddingService: embeddingService)
        let results = ragService.search(query: question, topK: 3, context: context)

        if results.isEmpty {
            return .result(
                value: "No results found.",
                dialog: "I couldn't find any meetings matching your question."
            )
        }

        let response = results.map(\.chunkText).joined(separator: "\n")
        return .result(
            value: response,
            dialog: IntentDialog(stringLiteral: response)
        )
    }
}
