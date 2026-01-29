import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.theme) private var theme
    let person: Person
    @State private var relationshipSummary: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.xl) {
                // Header
                VStack(spacing: theme.spacing.md) {
                    PersonAvatarView(name: person.name, size: 80)

                    Text(person.name)
                        .font(theme.typography.displayFont)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(person.email)
                        .font(theme.typography.captionFont)
                        .foregroundStyle(theme.colors.textSecondary)

                    HStack(spacing: theme.spacing.xl) {
                        StatView(value: "\(person.meetingCount)", label: "Meetings")
                        if let lastSeen = person.lastSeenDate {
                            StatView(value: lastSeen.formatted(as: .shortDate), label: "Last Seen")
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .themedCard()

                // Relationship summary
                if let summary = relationshipSummary {
                    VStack(alignment: .leading, spacing: theme.spacing.sm) {
                        Text("Relationship")
                            .themedHeading()
                        Text(summary)
                            .themedBody()
                    }
                    .themedCard()
                }

                // Meeting history
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    Text("Meeting History")
                        .themedHeading()

                    if person.meetings.isEmpty {
                        Text("No meetings recorded.")
                            .themedCaption()
                    } else {
                        let sortedMeetings = person.meetings.sorted { $0.startDate > $1.startDate }
                        ForEach(sortedMeetings) { meeting in
                            NavigationLink(value: meeting) {
                                HStack {
                                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                                        Text(meeting.title)
                                            .themedBody()
                                        Text(meeting.startDate.formatted(as: .dateTime))
                                            .themedCaption()
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(theme.colors.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)

                            if meeting.id != sortedMeetings.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .themedCard()
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background)
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MeetingRecord.self) { meeting in
            MeetingDetailView(meeting: meeting)
        }
        .task {
            let service = SummarizationService()
            relationshipSummary = await service.generateRelationshipSummary(
                for: person,
                meetings: person.meetings
            )
        }
    }
}

private struct StatView: View {
    @Environment(\.theme) private var theme
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: theme.spacing.xxs) {
            Text(value)
                .font(theme.typography.headingFont)
                .fontWeight(.bold)
                .foregroundStyle(theme.colors.accent)
            Text(label)
                .font(theme.typography.captionFont)
                .foregroundStyle(theme.colors.textSecondary)
        }
    }
}
