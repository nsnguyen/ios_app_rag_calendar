import SwiftUI
import SwiftData

struct SearchView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var aiAnswer: String?
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var showMoreResults = false
    @State private var selectedDay: Date?
    @State private var navigationPath = NavigationPath()

    private let relevanceThreshold: Double = 0.55

    private var topResults: [SearchResult] {
        results.filter { $0.score >= relevanceThreshold }
    }

    private var moreResults: [SearchResult] {
        results.filter { $0.score < relevanceThreshold }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: theme.spacing.md) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(theme.colors.textSecondary)

                TextField("Ask about your meetings and notes...", text: $query)
                    .font(theme.typography.bodyFont)
                    .onSubmit { performSearch() }

                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                        aiAnswer = nil
                        hasSearched = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(theme.colors.textTertiary)
                    }
                }
            }
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.inputRadius, style: .continuous))
            .padding(.horizontal, theme.spacing.lg)
            .padding(.vertical, theme.spacing.md)

            // Results
            if isSearching {
                Spacer()
                ProgressView("Searching...")
                    .themedCaption()
                Spacer()
            } else if hasSearched && results.isEmpty {
                EmptyStateView(
                    title: "No Results",
                    systemImage: "magnifyingglass",
                    description: "Try rephrasing your question."
                )
            } else if !results.isEmpty {
                ScrollView {
                    VStack(spacing: theme.spacing.lg) {
                        // AI Answer Card
                        if let answer = aiAnswer {
                            AIAnswerCard(answer: answer)
                                .padding(.horizontal, theme.spacing.lg)
                        }

                        // Top Results
                        if !topResults.isEmpty {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                Text("Top Results")
                                    .font(theme.typography.captionFont)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .padding(.horizontal, theme.spacing.lg)

                                LazyVStack(spacing: 0) {
                                    ForEach(topResults) { result in
                                        resultLink(result: result)
                                            .padding(.horizontal, theme.spacing.lg)
                                        if result.id != topResults.last?.id {
                                            Divider()
                                                .padding(.leading, theme.spacing.lg)
                                        }
                                    }
                                }
                            }
                        }

                        // More Results (collapsed)
                        if !moreResults.isEmpty {
                            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showMoreResults.toggle()
                                    }
                                } label: {
                                    HStack(spacing: theme.spacing.xs) {
                                        Text("Show \(moreResults.count) more result\(moreResults.count == 1 ? "" : "s")")
                                            .font(theme.typography.captionFont)
                                            .foregroundStyle(theme.colors.textSecondary)
                                        Image(systemName: showMoreResults ? "chevron.up" : "chevron.down")
                                            .font(.caption2)
                                            .foregroundStyle(theme.colors.textTertiary)
                                    }
                                    .padding(.horizontal, theme.spacing.lg)
                                }

                                if showMoreResults {
                                    LazyVStack(spacing: 0) {
                                        ForEach(moreResults) { result in
                                            resultLink(result: result)
                                                .padding(.horizontal, theme.spacing.lg)
                                                .opacity(0.6)
                                            if result.id != moreResults.last?.id {
                                                Divider()
                                                    .padding(.leading, theme.spacing.lg)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, theme.spacing.md)
                }
            } else {
                EmptyStateView(
                    title: "Semantic Search",
                    systemImage: "sparkle.magnifyingglass",
                    description: "Ask a question about your meetings or notes."
                )
            }
        }
        .background(theme.colors.background)
        .navigationTitle("Search")
        .navigationDestination(for: Note.self) { note in
            NoteEditorView(note: note)
        }
        .fullScreenCover(item: $selectedDay) { date in
            NavigationStack {
                DayPageView(
                    date: date,
                    onMeetingTap: { _ in },
                    onNoteTap: { _ in },
                    onAddNote: {}
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") { selectedDay = nil }
                    }
                }
            }
        }
    }

    private func performSearch() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        aiAnswer = nil
        showMoreResults = false

        Task {
            results = appServices.ragService.search(query: query, topK: 10, context: modelContext)

            // Generate AI answer from top results
            if !results.isEmpty {
                aiAnswer = await appServices.summarizationService.answerQuestion(query, fromContext: results)
            }

            hasSearched = true
            isSearching = false
        }
    }

    @ViewBuilder
    private func resultLink(result: SearchResult) -> some View {
        if let note = result.embeddingRecord.note {
            NavigationLink(value: note) {
                SearchResultRow(result: result)
            }
            .buttonStyle(.plain)
        } else if let meeting = result.embeddingRecord.meetingRecord {
            Button {
                selectedDay = meeting.startDate
            } label: {
                SearchResultRow(result: result)
            }
            .buttonStyle(.plain)
        } else {
            SearchResultRow(result: result)
        }
    }
}

// MARK: - Search Result Row

private struct SearchResultRow: View {
    @Environment(\.theme) private var theme
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            HStack {
                Image(systemName: result.sourceType == "meeting" ? "calendar" : "note.text")
                    .foregroundStyle(theme.colors.accent)
                Text(result.sourceType == "meeting" ? "Meeting" : "Note")
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textSecondary)
                Spacer()
                Text(String(format: "%.0f%%", result.score * 100))
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textTertiary)
            }

            Text(result.chunkText)
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(3)
        }
        .padding(.vertical, theme.spacing.xs)
    }
}

// MARK: - AI Answer Card

private struct AIAnswerCard: View {
    @Environment(\.theme) private var theme
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack(spacing: theme.spacing.sm) {
                Image(systemName: "sparkles")
                    .foregroundStyle(theme.colors.accent)
                Text("AI Answer")
                    .font(theme.typography.captionFont.weight(.semibold))
                    .foregroundStyle(theme.colors.accent)
            }

            Text(answer)
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous)
                .strokeBorder(theme.colors.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

