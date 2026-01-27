---
name: ondevice-rag-engine
description: Build the on-device RAG (Retrieval-Augmented Generation) engine using NaturalLanguage framework embeddings, vector storage in SwiftData, and Accelerate-powered similarity search. This skill should be used when implementing semantic search, embedding generation, chunking, indexing, or vector similarity for the planner app.
---

# On-Device RAG Engine

## Overview

Implement a fully on-device retrieval-augmented generation pipeline. The RAG engine generates sentence embeddings using Apple's NaturalLanguage framework, stores vectors in SwiftData, and performs cosine similarity search using the Accelerate framework. No data leaves the device.

## Embedding Generation

### NLEmbedding Setup

```swift
import NaturalLanguage

final class EmbeddingService {
    private let embedding: NLEmbedding?

    init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
    }

    var isAvailable: Bool { embedding != nil }

    func generateVector(for text: String) -> [Double]? {
        embedding?.vector(for: text)
    }

    func generateVectors(for texts: [String]) -> [[Double]?] {
        texts.map { embedding?.vector(for: $0) }
    }
}
```

Critical notes:
- `NLEmbedding.sentenceEmbedding(for:)` returns `nil` if the model for that language is not downloaded to the device. Always check `isAvailable` before use.
- English sentence embeddings produce **512-dimensional** vectors.
- All computation is on-device with no network calls.
- The embedding model is loaded once and reused. Do not re-create `NLEmbedding` instances per query.

### Supported Languages

`NLEmbedding.supportedRevisions(for: .sentenceEmbedding)` lists available languages. English is the most reliable. For multi-language support, detect language first with `NLLanguageRecognizer` then load the appropriate model.

## Chunking Strategy

Meeting data must be split into chunks optimized for sentence embeddings. Chunks that are too long lose specificity; too short lose context.

### Meeting Record Chunking

For each `MeetingRecord`, generate these chunks:

1. **Title + Date**: `"Meeting: {title} on {formatted date}"`
2. **Attendees**: `"Attendees: {comma-separated names}"`
3. **Purpose**: `"Purpose: {purpose}"` (if not nil)
4. **Outcomes**: `"Outcomes: {outcomes}"` (if not nil)
5. **Action Items**: `"Action items: {actionItems}"` (if not nil)
6. **Location**: `"Location: {location}"` (if not nil)

### Note Chunking

For each `Note`, split `plainText` into chunks:

1. Split on paragraph boundaries (double newline)
2. If a paragraph exceeds 200 words, split on sentence boundaries
3. Prepend the note title to the first chunk: `"Note: {title}. {first paragraph}"`
4. Target chunk size: 50-200 words (sweet spot for sentence embeddings)

```swift
func chunkText(_ text: String, title: String) -> [String] {
    let paragraphs = text.components(separatedBy: "\n\n")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

    var chunks: [String] = []
    for (index, paragraph) in paragraphs.enumerated() {
        let prefix = index == 0 ? "Note: \(title). " : ""
        let words = paragraph.split(separator: " ")
        if words.count > 200 {
            // Split on sentence boundaries
            let sentences = paragraph.components(separatedBy: ". ")
            var current = prefix
            for sentence in sentences {
                if current.split(separator: " ").count + sentence.split(separator: " ").count > 200 {
                    chunks.append(current)
                    current = sentence
                } else {
                    current += (current.isEmpty ? "" : ". ") + sentence
                }
            }
            if !current.isEmpty { chunks.append(current) }
        } else {
            chunks.append(prefix + paragraph)
        }
    }
    return chunks
}
```

## Vector Storage

### Data Conversion

Store `[Double]` as `Data` in SwiftData's `EmbeddingRecord`:

```swift
extension Array where Element == Double {
    var asData: Data {
        withUnsafeBytes { Data($0) }
    }
}

extension Data {
    var asDoubleArray: [Double] {
        withUnsafeBytes { Array($0.bindMemory(to: Double.self)) }
    }
}
```

### Indexing Pipeline

```swift
func indexMeetingRecord(_ record: MeetingRecord, context: ModelContext) async {
    // Delete existing embeddings for this record
    let existingEmbeddings = record.embeddings
    existingEmbeddings.forEach { context.delete($0) }

    // Generate chunks
    let chunks = generateMeetingChunks(record)

    // Generate and store embeddings
    for (index, chunk) in chunks.enumerated() {
        guard let vector = embeddingService.generateVector(for: chunk) else { continue }
        let embedding = EmbeddingRecord()
        embedding.vectorData = vector.asData
        embedding.sourceText = chunk
        embedding.sourceType = "meeting"
        embedding.chunkIndex = index
        embedding.createdAt = Date()
        embedding.meetingRecord = record
        context.insert(embedding)
    }
}
```

Run indexing on a background queue to avoid blocking the UI:

```swift
Task.detached(priority: .utility) {
    let context = ModelContext(modelContainer)
    await indexMeetingRecord(record, context: context)
    try? context.save()
}
```

## Similarity Search

### Cosine Similarity with Accelerate

Use vDSP for fast vector operations instead of naive loops:

```swift
import Accelerate

func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
    precondition(a.count == b.count)
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
```

### Search Implementation

```swift
struct SearchResult {
    let embeddingRecord: EmbeddingRecord
    let score: Double
}

func search(query: String, topK: Int = 5, context: ModelContext) -> [SearchResult] {
    guard let queryVector = embeddingService.generateVector(for: query) else { return [] }

    // Fetch all embeddings
    let descriptor = FetchDescriptor<EmbeddingRecord>()
    guard let allEmbeddings = try? context.fetch(descriptor) else { return [] }

    // Score each embedding
    let scored = allEmbeddings.compactMap { record -> SearchResult? in
        let vector = record.vectorData.asDoubleArray
        guard vector.count == queryVector.count else { return nil }
        let score = cosineSimilarity(queryVector, vector)
        return SearchResult(embeddingRecord: record, score: score)
    }

    // Return top-K sorted by descending score
    return scored.sorted { $0.score > $1.score }.prefix(topK).map { $0 }
}
```

### Performance Optimization

For large datasets (1000+ embeddings), loading all vectors into memory is expensive. Optimize:

1. **Pre-filter by date range**: Add a date predicate to the fetch to limit candidates
2. **Batch similarity**: Load vectors in batches of 100, compute similarities, keep running top-K
3. **Minimum threshold**: Skip results below 0.3 similarity (unlikely to be relevant)
4. **Cache query vectors**: If the same query is run repeatedly, cache its embedding

## Re-indexing

Trigger re-indexing when:
- A `MeetingRecord` is created or its text fields are updated
- A `Note` is saved with new or changed `plainText`
- A `MeetingRecord` is deleted (delete its `EmbeddingRecord` entries via cascade)

Avoid re-indexing unchanged records. Compare a hash of the concatenated chunk source text against a stored hash before regenerating.

## Query Pipeline Summary

1. User enters a natural language question
2. Embed the question using `NLEmbedding`
3. Fetch candidate `EmbeddingRecord` entries (optionally filtered by date/type)
4. Compute cosine similarity using Accelerate
5. Return top-K results with source text previews and links to source `MeetingRecord` or `Note`
6. Optionally pass results to the summarization service for a synthesized answer
