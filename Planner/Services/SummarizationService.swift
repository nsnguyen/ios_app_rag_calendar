import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

protocol SummarizationServiceProtocol: Sendable {
    func generateMeetingSummary(for meeting: MeetingRecord) async -> String?
    func extractActionItems(from meeting: MeetingRecord) async -> [String]
    func generateMeetingBrief(for meeting: MeetingRecord, previousMeetings: [MeetingRecord]) async -> MeetingBrief?
    func generateRelationshipSummary(for person: Person, meetings: [MeetingRecord]) async -> String?
    func generateWeeklyRecap(meetings: [MeetingRecord]) async -> String?
    func generateInspirationPhrase(meetingCount: Int, noteCount: Int, tone: InspirationPhrase.Tone) async -> String?
    func answerQuestion(_ question: String, fromContext: [SearchResult]) async -> String?
}

final class SummarizationService: SummarizationServiceProtocol, @unchecked Sendable {

    init() {}

    func generateMeetingSummary(for meeting: MeetingRecord) async -> String? {
        // Foundation Models available on iOS 26+
        guard #available(iOS 26, *) else {
            return fallbackMeetingSummary(for: meeting)
        }
        return await foundationModelSummary(for: meeting)
    }

    func extractActionItems(from meeting: MeetingRecord) async -> [String] {
        guard let notes = meeting.meetingNotes, !notes.isEmpty else { return [] }
        // Simple extraction: lines starting with "- [ ]", "TODO", "Action:"
        return notes.components(separatedBy: .newlines).compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- [ ]") || trimmed.uppercased().hasPrefix("TODO") || trimmed.uppercased().hasPrefix("ACTION:") {
                return trimmed
            }
            return nil
        }
    }

    func generateMeetingBrief(for meeting: MeetingRecord, previousMeetings: [MeetingRecord]) async -> MeetingBrief? {
        let attendeeNames = meeting.attendees.map(\.name).joined(separator: ", ")
        let attendeeSummary = meeting.attendees.isEmpty ? "No attendees listed" : "Meeting with \(attendeeNames)"

        let previousSummary: String? = if !previousMeetings.isEmpty {
            "You've had \(previousMeetings.count) previous meeting(s) with overlapping attendees."
        } else {
            nil
        }

        let actionItems = previousMeetings.flatMap { prev -> [String] in
            guard let items = prev.actionItems else { return [] }
            return items.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }

        return MeetingBrief(
            meetingTitle: meeting.title,
            meetingDate: meeting.startDate,
            attendeeSummary: attendeeSummary,
            previousMeetingsSummary: previousSummary,
            actionItemsFromLastTime: actionItems,
            suggestedTopics: [],
            relationshipContext: nil
        )
    }

    func generateRelationshipSummary(for person: Person, meetings: [MeetingRecord]) async -> String? {
        guard !meetings.isEmpty else { return nil }
        return "You've met with \(person.name) \(meetings.count) time(s). Last meeting: \(meetings.first?.title ?? "Unknown")."
    }

    func generateWeeklyRecap(meetings: [MeetingRecord]) async -> String? {
        guard !meetings.isEmpty else { return nil }
        return "This week you had \(meetings.count) meeting(s)."
    }

    func generateInspirationPhrase(meetingCount: Int, noteCount: Int, tone: InspirationPhrase.Tone) async -> String? {
        guard #available(iOS 26, *) else {
            return fallbackInspirationPhrase(meetingCount: meetingCount, tone: tone)
        }
        return await foundationModelInspiration(meetingCount: meetingCount, noteCount: noteCount, tone: tone)
    }

    func answerQuestion(_ question: String, fromContext results: [SearchResult]) async -> String? {
        guard !results.isEmpty else { return nil }

        guard #available(iOS 26, *) else {
            return fallbackAnswerQuestion(question, fromContext: results)
        }
        return await foundationModelAnswer(question, fromContext: results)
    }

    // MARK: - Foundation Models (iOS 26+)

    @available(iOS 26, *)
    private func foundationModelSummary(for meeting: MeetingRecord) async -> String? {
        // Foundation Models integration point
        // Uses LanguageModelSession for on-device summarization
        return fallbackMeetingSummary(for: meeting)
    }

    @available(iOS 26, *)
    private func foundationModelInspiration(meetingCount: Int, noteCount: Int, tone: InspirationPhrase.Tone) async -> String? {
        return fallbackInspirationPhrase(meetingCount: meetingCount, tone: tone)
    }

    @available(iOS 26, *)
    private func foundationModelAnswer(_ question: String, fromContext results: [SearchResult]) async -> String? {
        #if canImport(FoundationModels)
        // Build context from search results
        let context = results.prefix(3).map { result -> String in
            let source = result.sourceType == "meeting" ? "Meeting" : "Note"
            return "[\(source)] \(result.chunkText)"
        }.joined(separator: "\n\n")

        let prompt = """
        Based on the following information from my personal notes and meetings, answer this question naturally and concisely.

        Question: \(question)

        Relevant information:
        \(context)

        Provide a helpful, conversational answer in 2-3 sentences. If the information doesn't fully answer the question, say what you found.
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
        } catch {
            return fallbackAnswerQuestion(question, fromContext: results)
        }
        #else
        return fallbackAnswerQuestion(question, fromContext: results)
        #endif
    }

    // MARK: - Fallbacks

    private func fallbackMeetingSummary(for meeting: MeetingRecord) -> String? {
        var parts: [String] = []
        parts.append("Meeting: \(meeting.title)")
        if !meeting.attendees.isEmpty {
            parts.append("With: \(meeting.attendees.map(\.name).joined(separator: ", "))")
        }
        if let notes = meeting.meetingNotes, !notes.isEmpty {
            let preview = String(notes.prefix(200))
            parts.append("Notes: \(preview)")
        }
        return parts.joined(separator: ". ")
    }

    private func fallbackInspirationPhrase(meetingCount: Int, tone: InspirationPhrase.Tone) -> String {
        switch tone {
        case .warm:
            if meetingCount == 0 { return "A clear day ahead -- perfect for deep work." }
            return "You have \(meetingCount) meeting(s) today. You've got this."
        case .direct:
            if meetingCount == 0 { return "No meetings. Make it count." }
            return "\(meetingCount) meeting(s) on deck. Stay focused."
        case .reflective:
            if meetingCount == 0 { return "An open day is a gift. Use it wisely." }
            return "Each conversation today is a chance to learn something new."
        }
    }

    private func fallbackAnswerQuestion(_ question: String, fromContext results: [SearchResult]) -> String {
        let topResults = Array(results.prefix(3))
        guard !topResults.isEmpty else {
            return "I couldn't find relevant information to answer your question."
        }

        // Find the best result with actual content (not just short metadata)
        let contentResults = topResults.filter { $0.chunkText.count > 50 }

        if contentResults.isEmpty {
            // Fall back to combining the short results
            let combined = topResults.map { $0.chunkText }.joined(separator: " ")
            return truncateToSentences(combined, maxLength: 400)
        }

        // Build answer from the richest content
        var answerParts: [String] = []

        // Get the primary answer from the best match
        if let primary = contentResults.first {
            let cleaned = cleanChunkText(primary.chunkText)
            answerParts.append(truncateToSentences(cleaned, maxLength: 350))
        }

        // Add supplementary info from other good matches
        for result in contentResults.dropFirst().prefix(1) {
            let cleaned = cleanChunkText(result.chunkText)
            let supplement = truncateToSentences(cleaned, maxLength: 200)
            if !supplement.isEmpty && !answerParts.contains(where: { $0.contains(supplement.prefix(50)) }) {
                answerParts.append(supplement)
            }
        }

        return answerParts.joined(separator: "\n\n")
    }

    private func cleanChunkText(_ text: String) -> String {
        // Remove prefixes like "Notes from Meeting Title: " for cleaner answers
        var cleaned = text
        if let colonRange = cleaned.range(of: ": "), cleaned.hasPrefix("Notes from") {
            cleaned = String(cleaned[colonRange.upperBound...])
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func truncateToSentences(_ text: String, maxLength: Int) -> String {
        if text.count <= maxLength {
            return text
        }

        // Find the last sentence boundary before maxLength
        let truncated = String(text.prefix(maxLength))
        if let lastPeriod = truncated.lastIndex(of: ".") {
            return String(truncated[...lastPeriod])
        }
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }
}
