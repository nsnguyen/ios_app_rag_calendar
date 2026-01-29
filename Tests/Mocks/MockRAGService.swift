import Foundation
import SwiftData
@testable import Planner

final class MockRAGService: RAGServiceProtocol, @unchecked Sendable {
    var mockSearchResults: [SearchResult] = []
    var searchCallCount = 0
    var indexMeetingCallCount = 0
    var indexNoteCallCount = 0
    var lastQuery: String?

    func search(query: String, topK: Int, context: ModelContext) -> [SearchResult] {
        searchCallCount += 1
        lastQuery = query
        return Array(mockSearchResults.prefix(topK))
    }

    func indexMeetingRecord(_ meeting: MeetingRecord, context: ModelContext) {
        indexMeetingCallCount += 1
    }

    func indexNote(_ note: Note, context: ModelContext) {
        indexNoteCallCount += 1
    }
}
