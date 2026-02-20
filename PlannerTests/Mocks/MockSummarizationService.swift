import Foundation
@testable import Planner

final class MockSummarizationService: SummarizationServiceProtocol, @unchecked Sendable {
    var mockSummary: String? = "Mock summary"
    var mockActionItems: [String] = []
    var mockBrief: MeetingBrief?
    var mockRelationshipSummary: String?
    var mockWeeklyRecap: String?
    var mockInspirationPhrase: String? = "Stay focused."

    var generateSummaryCallCount = 0
    var extractActionItemsCallCount = 0
    var generateBriefCallCount = 0

    func generateMeetingSummary(for meeting: MeetingRecord) async -> String? {
        generateSummaryCallCount += 1
        return mockSummary
    }

    func extractActionItems(from meeting: MeetingRecord) async -> [String] {
        extractActionItemsCallCount += 1
        return mockActionItems
    }

    func generateMeetingBrief(for meeting: MeetingRecord, previousMeetings: [MeetingRecord]) async -> MeetingBrief? {
        generateBriefCallCount += 1
        return mockBrief
    }

    func generateRelationshipSummary(for person: Person, meetings: [MeetingRecord]) async -> String? {
        return mockRelationshipSummary
    }

    func generateWeeklyRecap(meetings: [MeetingRecord]) async -> String? {
        return mockWeeklyRecap
    }

    func generateInspirationPhrase(meetingCount: Int, noteCount: Int, tone: InspirationPhrase.Tone) async -> String? {
        return mockInspirationPhrase
    }

    var mockAnswer: String? = "Mock answer"
    var answerQuestionCallCount = 0

    func answerQuestion(_ question: String, fromContext: [SearchResult]) async -> String? {
        answerQuestionCallCount += 1
        return mockAnswer
    }
}
