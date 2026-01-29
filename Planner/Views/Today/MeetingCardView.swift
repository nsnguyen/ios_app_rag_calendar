import SwiftUI

struct MeetingCardView: View {
    @Environment(\.theme) private var theme
    let entry: TimelineEntry

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Time and title
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(entry.title)
                        .font(theme.typography.headingFont)
                        .fontWeight(theme.typography.headingWeight)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)

                    if entry.isAllDay {
                        Text("All Day")
                            .font(theme.typography.captionFont)
                            .foregroundStyle(theme.colors.textSecondary)
                    } else {
                        Text(timeRange)
                            .font(theme.typography.captionFont)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                Spacer()

                if entry.hasNotes {
                    Image(systemName: "note.text")
                        .font(.caption)
                        .foregroundStyle(theme.colors.accent)
                }
            }

            // Location
            if let location = entry.location, !location.isEmpty {
                Label(location, systemImage: "location")
                    .font(theme.typography.captionFont)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            // Attendees
            if !entry.attendeeNames.isEmpty {
                HStack(spacing: -6) {
                    let displayNames = Array(entry.attendeeNames.prefix(3))
                    ForEach(displayNames, id: \.self) { name in
                        PersonAvatarView(name: name, size: 28)
                    }

                    if entry.attendeeNames.count > 3 {
                        Text("+\(entry.attendeeNames.count - 3)")
                            .font(theme.typography.captionFont)
                            .foregroundStyle(theme.colors.textSecondary)
                            .padding(.leading, theme.spacing.sm)
                    }
                }
            }

            // Tags
            if !entry.tagNames.isEmpty {
                HStack(spacing: theme.spacing.xs) {
                    ForEach(entry.tagNames, id: \.self) { tagName in
                        Text(tagName)
                            .font(.caption2)
                            .padding(.horizontal, theme.spacing.sm)
                            .padding(.vertical, theme.spacing.xxs)
                            .background(theme.colors.tagBackground)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.meetingCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
        .shadow(
            color: theme.shadows.cardColor,
            radius: theme.shadows.cardRadius,
            x: theme.shadows.cardX,
            y: theme.shadows.cardY
        )
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: entry.startDate)) - \(formatter.string(from: entry.endDate))"
    }
}
