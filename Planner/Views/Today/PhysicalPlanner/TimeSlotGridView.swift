import SwiftUI

struct TimeSlotGridView: View {
    @Environment(\.theme) private var theme
    let meetings: [MeetingRecord]
    let date: Date
    let onMeetingTap: (MeetingRecord) -> Void

    // Time slot configuration
    private let startHour = 6
    private let endHour = 22

    var body: some View {
        GeometryReader { geometry in
            let hourHeight: CGFloat = 48
            let labelWidth: CGFloat = 44
            let contentWidth = geometry.size.width - labelWidth - theme.spacing.sm

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        // Hour lines and labels
                        ForEach(startHour...endHour, id: \.self) { hour in
                            HourRowView(
                                hour: hour,
                                labelWidth: labelWidth,
                                isCurrentHour: isCurrentHour(hour)
                            )
                            .offset(y: CGFloat(hour - startHour) * hourHeight)
                        }

                        // Current time indicator
                        if isToday {
                            currentTimeIndicator(labelWidth: labelWidth, hourHeight: hourHeight)
                        }

                        // Meeting cards positioned at their start times
                        ForEach(sortedMeetings) { meeting in
                            if !meeting.isAllDay {
                                meetingCardPositioned(
                                    meeting: meeting,
                                    labelWidth: labelWidth,
                                    hourHeight: hourHeight,
                                    contentWidth: contentWidth
                                )
                            }
                        }
                    }
                    .frame(height: CGFloat(endHour - startHour + 1) * hourHeight)
                    .padding(.trailing, theme.spacing.sm)
                    .id("timeGrid")
                }
                .onAppear {
                    // Scroll to current hour if today
                    if isToday {
                        let currentHour = Calendar.current.component(.hour, from: Date())
                        if currentHour >= startHour && currentHour <= endHour {
                            // Scroll handled by ScrollView's default behavior
                        }
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func meetingCardPositioned(
        meeting: MeetingRecord,
        labelWidth: CGFloat,
        hourHeight: CGFloat,
        contentWidth: CGFloat
    ) -> some View {
        let startOffset = timeOffset(for: meeting.startDate, hourHeight: hourHeight)
        let duration = meeting.endDate.timeIntervalSince(meeting.startDate) / 3600.0
        let cardHeight = max(CGFloat(duration) * hourHeight, 32) // Minimum height

        Button {
            onMeetingTap(meeting)
        } label: {
            CompactMeetingCard(meeting: meeting)
                .frame(width: contentWidth - theme.spacing.xs, height: cardHeight, alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .offset(x: labelWidth + theme.spacing.sm, y: startOffset)
    }

    private func currentTimeIndicator(labelWidth: CGFloat, hourHeight: CGFloat) -> some View {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let minute = Calendar.current.component(.minute, from: now)
        let offset = CGFloat(hour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight

        return HStack(spacing: 0) {
            Circle()
                .fill(theme.colors.accent)
                .frame(width: 8, height: 8)
                .offset(x: labelWidth - 4)

            Rectangle()
                .fill(theme.colors.accent)
                .frame(height: 1.5)
        }
        .offset(y: offset - 4)
    }

    // MARK: - Helpers

    private var sortedMeetings: [MeetingRecord] {
        meetings.filter { !$0.isAllDay }.sorted { $0.startDate < $1.startDate }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private func isCurrentHour(_ hour: Int) -> Bool {
        guard isToday else { return false }
        let currentHour = Calendar.current.component(.hour, from: Date())
        return currentHour == hour
    }

    private func timeOffset(for date: Date, hourHeight: CGFloat) -> CGFloat {
        let hour = Calendar.current.component(.hour, from: date)
        let minute = Calendar.current.component(.minute, from: date)
        let clampedHour = max(startHour, min(hour, endHour))
        return CGFloat(clampedHour - startHour) * hourHeight + CGFloat(minute) / 60.0 * hourHeight
    }
}

// MARK: - Hour Row View

private struct HourRowView: View {
    @Environment(\.theme) private var theme
    let hour: Int
    let labelWidth: CGFloat
    let isCurrentHour: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Hour label
            Text(hourString)
                .font(.caption2)
                .fontWeight(isCurrentHour ? .semibold : .regular)
                .foregroundStyle(isCurrentHour ? theme.colors.accent : theme.colors.textTertiary)
                .frame(width: labelWidth, alignment: .trailing)
                .padding(.trailing, theme.spacing.xs)

            // Horizontal line
            Rectangle()
                .fill(theme.textures.paperLine.opacity(theme.textures.paperLineOpacity))
                .frame(height: 0.5)
        }
    }

    private var hourString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date).lowercased()
    }
}
