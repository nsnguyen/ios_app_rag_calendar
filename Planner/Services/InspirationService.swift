import Foundation
import SwiftData

protocol InspirationServiceProtocol {
    func generatePhrase(meetings: [MeetingRecord], notes: [Note], tone: InspirationPhrase.Tone) async -> InspirationPhrase
}

final class InspirationService: InspirationServiceProtocol {
    private let summarizationService: SummarizationServiceProtocol

    init(summarizationService: SummarizationServiceProtocol) {
        self.summarizationService = summarizationService
    }

    func generatePhrase(
        meetings: [MeetingRecord],
        notes: [Note],
        tone: InspirationPhrase.Tone
    ) async -> InspirationPhrase {
        let text = await summarizationService.generateInspirationPhrase(
            meetingCount: meetings.count,
            noteCount: notes.count,
            tone: tone
        ) ?? defaultPhrase(for: tone)

        return InspirationPhrase(text: text, tone: tone)
    }

    private func defaultPhrase(for tone: InspirationPhrase.Tone) -> String {
        switch tone {
        case .warm: "Every day is a fresh start."
        case .direct: "Focus on what matters."
        case .reflective: "Take a moment to plan your day."
        }
    }
}
