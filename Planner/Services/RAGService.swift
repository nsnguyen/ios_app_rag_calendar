import Accelerate
import Foundation
import SwiftData

protocol RAGServiceProtocol: Sendable {
    func search(query: String, topK: Int, context: ModelContext) -> [SearchResult]
    func indexMeetingRecord(_ meeting: MeetingRecord, context: ModelContext)
    func indexNote(_ note: Note, context: ModelContext)
}

final class RAGService: RAGServiceProtocol, @unchecked Sendable {
    private let embeddingService: EmbeddingServiceProtocol
    private let similarityThreshold: Double = 0.3
    private let defaultTopK: Int = 5

    init(embeddingService: EmbeddingServiceProtocol) {
        self.embeddingService = embeddingService
    }

    // MARK: - Search

    func search(query: String, topK: Int = 5, context: ModelContext) -> [SearchResult] {
        guard let queryVector = embeddingService.generateVector(for: query) else {
            return []
        }

        let descriptor = FetchDescriptor<EmbeddingRecord>()
        guard let allEmbeddings = try? context.fetch(descriptor) else {
            return []
        }

        // Extract keywords from query for hybrid search
        let queryKeywords = extractKeywords(from: query)

        let results = allEmbeddings.compactMap { record -> SearchResult? in
            let recordVector = record.vector
            guard recordVector.count == queryVector.count else { return nil }

            // Semantic similarity score
            let semanticScore = cosineSimilarity(queryVector, recordVector)

            // Keyword match boost
            let keywordBoost = calculateKeywordBoost(keywords: queryKeywords, text: record.chunkText)

            // Combined score: semantic + keyword boost (capped at 1.0)
            let combinedScore = min(1.0, semanticScore + keywordBoost)

            guard combinedScore >= similarityThreshold else { return nil }
            return SearchResult(embeddingRecord: record, score: combinedScore)
        }

        return results
            .sorted { $0.score > $1.score }
            .prefix(topK)
            .map { $0 }
    }

    private func extractKeywords(from query: String) -> [String] {
        // Split query into words, lowercase, filter short words and common stop words
        let stopWords: Set<String> = ["the", "a", "an", "is", "are", "was", "were", "be", "been",
                                       "being", "have", "has", "had", "do", "does", "did", "will",
                                       "would", "could", "should", "may", "might", "can", "to",
                                       "of", "in", "for", "on", "with", "at", "by", "from", "as",
                                       "into", "about", "what", "which", "who", "whom", "this",
                                       "that", "these", "those", "am", "my", "me", "i", "you",
                                       "your", "tell", "show", "find", "get", "give"]

        return query.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
    }

    private func calculateKeywordBoost(keywords: [String], text: String) -> Double {
        guard !keywords.isEmpty else { return 0 }

        let lowerText = text.lowercased()
        var matchCount = 0
        var exactPhraseBoost = 0.0

        for keyword in keywords {
            if lowerText.contains(keyword) {
                matchCount += 1

                // Extra boost for title matches (appears early in text)
                if lowerText.prefix(100).contains(keyword) {
                    exactPhraseBoost += 0.1
                }
            }
        }

        // Base boost: 0.15 per keyword match
        let baseBoost = Double(matchCount) * 0.15 / Double(keywords.count)

        return min(0.5, baseBoost + exactPhraseBoost) // Cap keyword boost at 0.5
    }

    // MARK: - Indexing

    func indexMeetingRecord(_ meeting: MeetingRecord, context: ModelContext) {
        // Remove old embeddings
        for embedding in meeting.embeddings {
            context.delete(embedding)
        }

        let chunks = chunkMeeting(meeting)
        for (index, chunk) in chunks.enumerated() {
            guard let vector = embeddingService.generateVector(for: chunk) else { continue }
            let record = EmbeddingRecord(
                chunkText: chunk,
                vector: vector,
                sourceType: "meeting",
                chunkIndex: index,
                meetingRecord: meeting
            )
            context.insert(record)
        }

        try? context.save()
    }

    func indexNote(_ note: Note, context: ModelContext) {
        // Clear existing embeddings if any
        let existingEmbeddings = note.embeddings
        for embedding in existingEmbeddings {
            context.delete(embedding)
        }
        note.embeddings.removeAll()

        let chunks = chunkNote(note)
        guard !chunks.isEmpty else { return }

        for (index, chunk) in chunks.enumerated() {
            guard let vector = embeddingService.generateVector(for: chunk) else { continue }
            let record = EmbeddingRecord(
                chunkText: chunk,
                vector: vector,
                sourceType: "note",
                chunkIndex: index,
                note: note
            )
            context.insert(record)
        }

        try? context.save()
    }

    // MARK: - Chunking

    private func chunkMeeting(_ meeting: MeetingRecord) -> [String] {
        var chunks: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: meeting.startDate)
        let attendeeNames = meeting.attendees.map(\.name).joined(separator: ", ")

        // Chunk 1: Meeting overview with title, date, and attendees
        var overview = "Meeting: \(meeting.title) on \(dateStr)"
        if !attendeeNames.isEmpty {
            overview += " with \(attendeeNames)"
        }
        if let location = meeting.location, !location.isEmpty {
            overview += " at \(location)"
        }
        chunks.append(overview)

        // Chunk 2: Meeting notes (the main content) - split into paragraphs if long
        if let notes = meeting.meetingNotes, !notes.isEmpty {
            let paragraphs = notes.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            var currentChunk = "Notes from \(meeting.title): "

            for paragraph in paragraphs {
                if currentChunk.count + paragraph.count > 500 {
                    chunks.append(currentChunk)
                    currentChunk = "Notes from \(meeting.title) (continued): " + paragraph
                } else {
                    currentChunk += paragraph + " "
                }
            }
            if currentChunk.count > 30 { // More than just the prefix
                chunks.append(currentChunk)
            }
        }

        // Chunk 3: Purpose and outcomes together
        var purposeOutcomes = ""
        if let purpose = meeting.purpose, !purpose.isEmpty {
            purposeOutcomes = "Purpose of \(meeting.title): \(purpose)"
        }
        if let outcomes = meeting.outcomes, !outcomes.isEmpty {
            if !purposeOutcomes.isEmpty {
                purposeOutcomes += " Outcome: \(outcomes)"
            } else {
                purposeOutcomes = "Outcome of \(meeting.title): \(outcomes)"
            }
        }
        if !purposeOutcomes.isEmpty {
            chunks.append(purposeOutcomes)
        }

        // Chunk 4: Action items
        if let actionItems = meeting.actionItems, !actionItems.isEmpty {
            chunks.append("Action items from \(meeting.title): \(actionItems)")
        }

        return chunks
    }

    private func chunkNote(_ note: Note) -> [String] {
        let text = note.plainText
        guard !text.isEmpty else { return [] }

        let title = note.title.isEmpty ? "Untitled Note" : note.title

        // For notes, create simpler chunks - one with full content (truncated if too long)
        // and include title for better searchability
        var chunks: [String] = []

        // Main chunk: Title + beginning of content
        let maxChunkLength = 500
        let fullText = "Note '\(title)': \(text)"

        if fullText.count <= maxChunkLength {
            // Short note - just one chunk
            chunks.append(fullText)
        } else {
            // Split into multiple chunks by paragraphs
            let paragraphs = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

            var currentChunk = "Note '\(title)': "

            for paragraph in paragraphs {
                let potentialChunk = currentChunk + paragraph + " "

                if potentialChunk.count > maxChunkLength && currentChunk.count > 30 {
                    // Save current chunk and start new one
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespaces))
                    currentChunk = "Note '\(title)' (continued): \(paragraph) "
                } else {
                    currentChunk = potentialChunk
                }
            }

            // Add final chunk if it has content
            let trimmed = currentChunk.trimmingCharacters(in: .whitespaces)
            if trimmed.count > 30 {
                chunks.append(trimmed)
            }
        }

        return chunks
    }

    // MARK: - Cosine Similarity

    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }

        var dotProduct: Double = 0
        var normA: Double = 0
        var normB: Double = 0

        vDSP_dotprD(a, 1, b, 1, &dotProduct, vDSP_Length(a.count))
        vDSP_dotprD(a, 1, a, 1, &normA, vDSP_Length(a.count))
        vDSP_dotprD(b, 1, b, 1, &normB, vDSP_Length(b.count))

        let denominator = sqrt(normA) * sqrt(normB)
        guard denominator > 0 else { return 0 }
        return dotProduct / denominator
    }
}
