---
name: apple-intelligence-summarization
description: Integrate Apple Intelligence on-device Foundation models for meeting summarization, action item extraction, and meeting brief generation. This skill should be used when implementing AI-powered text summarization, meeting recaps, or content synthesis for the planner app.
---

# Apple Intelligence — Summarization

## Overview

Use Apple's on-device Foundation models to summarize meeting notes, generate meeting briefs, extract action items, and create relationship summaries. All processing runs on-device with no data leaving the phone. Requires iOS 18+ and Apple Intelligence-capable hardware (A17 Pro or later, M-series).

## Device Capability Check

Always check availability before attempting to use Foundation models:

```swift
import FoundationModels

@available(iOS 26, *)
func isAppleIntelligenceAvailable() -> Bool {
    SystemLanguageModel.default.isAvailable
}
```

**Important**: The Foundation Models framework was introduced at WWDC25 for iOS 26. For iOS 18, use the Writing Tools API or consider alternative approaches. Verify the exact API surface against the latest Apple documentation, as this is a rapidly evolving area.

### Fallback Strategy

When Apple Intelligence is unavailable:
1. Show cached summaries if previously generated
2. Display raw meeting notes without summarization
3. Offer a "summarize when available" option that queues the request
4. Never crash or show an error — degrade gracefully

## Summarization Service

```swift
@available(iOS 26, *)
@Observable
final class SummarizationService {
    private var session: LanguageModelSession?

    func generateMeetingSummary(for record: MeetingRecord) async throws -> String {
        let session = LanguageModelSession()

        let prompt = """
        Summarize this meeting concisely in 2-3 sentences:
        Title: \(record.title)
        Date: \(record.startDate.formatted())
        Attendees: \(record.attendees.map(\.name).joined(separator: ", "))
        Purpose: \(record.purpose ?? "Not specified")
        Notes: \(record.notes.map(\.plainText).joined(separator: "\n"))
        Outcomes: \(record.outcomes ?? "Not recorded")
        """

        let response = try await session.respond(to: prompt)
        return response.content
    }
}
```

Non-obvious:
- `LanguageModelSession` manages conversation context. Create a new session per summarization task to avoid context bleed between different meetings.
- The model runs fully on-device. Response generation is async and may take a few seconds.
- The response is text-only. Parse structured data (like action items) from the text output.

## Prompt Templates

### Meeting Recap

```swift
let meetingRecapPrompt = """
Provide a brief recap of this meeting:
- Title: \(title)
- Date: \(date)
- Attendees: \(attendees)
- Notes: \(notes)

Format: 2-3 sentences covering what was discussed and any decisions made.
"""
```

### Action Item Extraction

```swift
let actionItemPrompt = """
Extract action items from these meeting notes. List each as a single line starting with "- [ ]".
If no action items are found, respond with "No action items identified."

Meeting: \(title)
Notes: \(notes)
"""
```

Parse the response by splitting on newlines and filtering lines starting with `- [ ]`.

### Meeting Brief (Pre-Meeting)

Generate before an upcoming meeting to remind the user of past context:

```swift
func generateMeetingBrief(
    upcomingTitle: String,
    attendeeNames: [String],
    pastMeetings: [MeetingRecord]
) async throws -> String {
    let pastContext = pastMeetings.map { record in
        "- \(record.title) on \(record.startDate.formatted()): \(record.summary ?? record.outcomes ?? "No summary")"
    }.joined(separator: "\n")

    let prompt = """
    Prepare a brief for an upcoming meeting:
    Meeting: \(upcomingTitle)
    Attendees: \(attendeeNames.joined(separator: ", "))

    Past meetings with these attendees:
    \(pastContext)

    Provide a 2-3 sentence brief covering: what was previously discussed, any outstanding action items, and suggested topics for this meeting.
    """

    let session = LanguageModelSession()
    let response = try await session.respond(to: prompt)
    return response.content
}
```

### Relationship Summary

Generate a summary of interactions with a specific person:

```swift
let relationshipPrompt = """
Summarize the professional relationship based on these meetings:
Person: \(person.name)
Meeting history:
\(meetings.map { "- \($0.title) on \($0.startDate.formatted())" }.joined(separator: "\n"))

Provide a 1-2 sentence summary of how often they meet and what they typically discuss.
"""
```

## Caching Summaries

Store generated summaries to avoid re-computation:

```swift
func summarizeAndCache(_ record: MeetingRecord, context: ModelContext) async {
    // Skip if already summarized
    guard record.summary == nil else { return }

    do {
        let summary = try await generateMeetingSummary(for: record)
        record.summary = summary
        record.updatedAt = Date()
        try context.save()
    } catch {
        // Log error, don't crash — summarization is a nice-to-have
    }
}
```

## Batch Summarization

Summarize multiple meetings (e.g., weekly recap):

```swift
func generateWeeklyRecap(meetings: [MeetingRecord]) async throws -> String {
    let meetingList = meetings.map { record in
        "- \(record.title) (\(record.startDate.formatted(date: .abbreviated, time: .shortened))): \(record.summary ?? "No summary")"
    }.joined(separator: "\n")

    let prompt = """
    Provide a weekly meeting recap. Highlight key themes, important decisions, and outstanding action items.

    This week's meetings:
    \(meetingList)

    Format: A brief paragraph followed by bullet points for action items.
    """

    let session = LanguageModelSession()
    let response = try await session.respond(to: prompt)
    return response.content
}
```

## Resource Management

- Create `LanguageModelSession` instances on-demand, not at app launch
- Do not hold long-lived session references — the model consumes device resources
- Use `Task.detached(priority: .utility)` for summarization to avoid blocking UI
- Rate-limit batch operations — space requests to avoid thermal throttling
- Cancel in-flight summarization tasks when the user navigates away

## iOS 18 Alternative: Writing Tools

If targeting iOS 18 specifically (before Foundation Models framework), consider using the system Writing Tools integration:

```swift
// UITextView automatically gets Writing Tools support in iOS 18
textView.writingToolsBehavior = .complete
```

This gives users access to system-level summarization, proofreading, and rewriting via the standard text selection menu. Less programmatic control but zero implementation cost.
