import Testing
import Foundation
import SwiftData
@testable import Planner

@Suite("Inspiration Service Tests")
struct InspirationServiceTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: MeetingRecord.self, Note.self, Person.self, EmbeddingRecord.self, Tag.self,
            configurations: config
        )
    }

    @Test("Generate phrase for each tone")
    func generatePhraseForTones() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let mockSummarization = MockSummarizationService()
        let service = InspirationService(summarizationService: mockSummarization)

        for tone in InspirationPhrase.Tone.allCases {
            let phrase = await service.generatePhrase(meetings: [], notes: [], tone: tone)
            #expect(!phrase.text.isEmpty)
            #expect(phrase.tone == tone)
        }
    }

    @Test("Generate phrase with meetings context")
    func phraseWithMeetings() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let meeting = TestFixtures.makeMeeting()
        context.insert(meeting)

        let mockSummarization = MockSummarizationService()
        mockSummarization.mockInspirationPhrase = "Big day ahead!"

        let service = InspirationService(summarizationService: mockSummarization)
        let phrase = await service.generatePhrase(meetings: [meeting], notes: [], tone: .warm)

        #expect(phrase.text == "Big day ahead!")
    }

    @Test("Fallback phrase when summarization returns nil")
    func fallbackPhrase() async {
        let mockSummarization = MockSummarizationService()
        mockSummarization.mockInspirationPhrase = nil

        let service = InspirationService(summarizationService: mockSummarization)
        let phrase = await service.generatePhrase(meetings: [], notes: [], tone: .direct)

        #expect(!phrase.text.isEmpty)
        #expect(phrase.tone == .direct)
    }
}
