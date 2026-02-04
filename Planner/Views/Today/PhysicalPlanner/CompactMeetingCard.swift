import SwiftUI

struct CompactMeetingCard: View {
    @Environment(\.theme) private var theme
    let meeting: MeetingRecord

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Time indicator bar
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.colors.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                // Title
                Text(meeting.title)
                    .font(theme.typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)

                // Time range
                if !meeting.isAllDay {
                    Text(timeRange)
                        .font(.caption2)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }

            Spacer(minLength: 0)

            // Location indicator
            if meeting.location != nil && !meeting.location!.isEmpty {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(theme.colors.textTertiary)
            }

            // Attendee avatars (max 2)
            if !meeting.attendees.isEmpty {
                HStack(spacing: -4) {
                    ForEach(Array(meeting.attendees.prefix(2))) { person in
                        PersonAvatarView(name: person.name, size: 18)
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.sm)
        .padding(.vertical, theme.spacing.xs)
        .background(theme.colors.meetingCard.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.chipRadius / 2, style: .continuous))
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: meeting.startDate)) - \(formatter.string(from: meeting.endDate))"
    }
}
