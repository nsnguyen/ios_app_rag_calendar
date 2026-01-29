import Foundation
import SwiftData

/// Shared dependency injection container for all app services.
/// Created once in PlannerApp and injected via @Environment.
@Observable
@MainActor
final class AppServices {
    let calendarService: CalendarServiceProtocol
    let embeddingService: EmbeddingServiceProtocol
    let ragService: RAGServiceProtocol
    let summarizationService: SummarizationServiceProtocol
    let meetingContextService: MeetingContextService
    let spotlightService: SpotlightServiceProtocol
    let inspirationService: InspirationServiceProtocol

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        embeddingService: EmbeddingServiceProtocol? = nil,
        summarizationService: SummarizationServiceProtocol = SummarizationService(),
        spotlightService: SpotlightServiceProtocol = SpotlightService()
    ) {
        let embedding = embeddingService ?? EmbeddingService()
        let rag = RAGService(embeddingService: embedding)

        self.calendarService = calendarService
        self.embeddingService = embedding
        self.ragService = rag
        self.summarizationService = summarizationService
        self.spotlightService = spotlightService
        self.inspirationService = InspirationService(summarizationService: summarizationService)
        self.meetingContextService = MeetingContextService(
            calendarService: calendarService,
            ragService: rag,
            embeddingService: embedding,
            summarizationService: summarizationService
        )
    }
}
