import SwiftUI
import SwiftData

struct MeetingDetailView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices
    let meeting: MeetingRecord
    @State private var brief: MeetingBrief?
    @State private var isLoadingBrief = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                headerSection
                briefSection
                attendeesSection
                notesSection
                detailsSection
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background)
        .navigationTitle(meeting.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await loadBrief()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            if meeting.isAllDay {
                Label("All Day", systemImage: "sun.max")
                    .themedCaption()
            } else {
                Label(timeString, systemImage: "clock")
                    .themedCaption()
            }

            if let location = meeting.location, !location.isEmpty {
                Label(location, systemImage: "location")
                    .themedCaption()
            }

            if let summary = meeting.summary {
                Text(summary)
                    .themedBody()
                    .padding(.top, theme.spacing.xs)
            }
        }
        .themedCard()
    }

    @ViewBuilder
    private var briefSection: some View {
        if isLoadingBrief {
            ProgressView("Preparing brief...")
                .themedCard()
        } else if let brief {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Meeting Brief")
                    .themedHeading()

                Text(brief.attendeeSummary)
                    .themedBody()

                if let previousSummary = brief.previousMeetingsSummary {
                    Text(previousSummary)
                        .themedCaption()
                }

                if !brief.actionItemsFromLastTime.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Open Action Items")
                            .font(theme.typography.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.colors.textSecondary)

                        ForEach(brief.actionItemsFromLastTime, id: \.self) { item in
                            HStack(alignment: .top, spacing: theme.spacing.sm) {
                                Image(systemName: "circle")
                                    .font(.caption2)
                                    .foregroundStyle(theme.colors.accent)
                                Text(item)
                                    .themedCaption()
                            }
                        }
                    }
                }
            }
            .themedCard()
        }
    }

    @ViewBuilder
    private var attendeesSection: some View {
        if !meeting.attendees.isEmpty {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                Text("Attendees")
                    .themedHeading()

                ForEach(meeting.attendees) { person in
                    HStack(spacing: theme.spacing.md) {
                        PersonAvatarView(name: person.name, size: 36)
                        VStack(alignment: .leading) {
                            Text(person.name)
                                .themedBody()
                            Text(person.email)
                                .themedCaption()
                        }
                    }
                }
            }
            .themedCard()
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.md) {
            HStack {
                Text("Notes")
                    .themedHeading()
                Spacer()
                NavigationLink {
                    NoteEditorView(meetingRecord: meeting)
                } label: {
                    Label("Add Note", systemImage: "plus")
                        .font(theme.typography.captionFont)
                }
            }

            if meeting.notes.isEmpty {
                Text("No notes yet. Tap + to add one.")
                    .themedCaption()
            } else {
                ForEach(meeting.notes) { note in
                    NavigationLink {
                        NoteEditorView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .themedBody()
                            Text(note.plainText.prefix(100) + (note.plainText.count > 100 ? "..." : ""))
                                .themedCaption()
                                .lineLimit(2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .themedCard()
    }

    @ViewBuilder
    private var detailsSection: some View {
        if meeting.purpose != nil || meeting.outcomes != nil || meeting.actionItems != nil {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                if let purpose = meeting.purpose, !purpose.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Purpose")
                            .font(theme.typography.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.colors.textSecondary)
                        Text(purpose)
                            .themedBody()
                    }
                }

                if let outcomes = meeting.outcomes, !outcomes.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Outcomes")
                            .font(theme.typography.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.colors.textSecondary)
                        Text(outcomes)
                            .themedBody()
                    }
                }

                if let actionItems = meeting.actionItems, !actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Action Items")
                            .font(theme.typography.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.colors.textSecondary)
                        Text(actionItems)
                            .themedBody()
                    }
                }
            }
            .themedCard()
        }
    }

    // MARK: - Static DateFormatter (cached)

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    // MARK: - Helpers

    private var timeString: String {
        "\(Self.timeFormatter.string(from: meeting.startDate)) - \(Self.timeFormatter.string(from: meeting.endDate))"
    }

    private func loadBrief() async {
        isLoadingBrief = true
        brief = await appServices.meetingContextService.generateBrief(
            for: meeting,
            context: modelContext
        )
        isLoadingBrief = false
    }
}
