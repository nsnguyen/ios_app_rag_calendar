import SwiftUI
import SwiftData

struct WeekSpreadView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices

    let weekStartDate: Date // Monday of the week
    let onDayExpand: (Date) -> Void
    let onMeetingTap: (MeetingRecord) -> Void

    @State private var weekData: [Date: DayData] = [:]

    struct DayData {
        var meetings: [MeetingRecord]
        var notes: [Note]
        var tasks: [DayTask]
    }

    var body: some View {
        GeometryReader { geometry in
            let dividerWidth: CGFloat = 1
            let pageWidth = (geometry.size.width - dividerWidth) / 2
            let availableHeight = geometry.size.height

            ZStack {
                // Paper background
                theme.textures.paperBase

                HStack(spacing: 0) {
                    // Left page: Mon, Tue, Wed (3 days)
                    leftPage(width: pageWidth, height: availableHeight)

                    // Subtle center divider
                    Rectangle()
                        .fill(theme.textures.paperLine.opacity(0.3))
                        .frame(width: dividerWidth)

                    // Right page: Thu, Fri, Sat, Sun (4 days)
                    rightPage(width: pageWidth, height: availableHeight)
                }

                // Page curl hint - subtle shadow on right edge
                HStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.03), .black.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 20)
                }

                // Lifted corner hint
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PageCornerHint()
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .task {
            loadWeekData()
        }
    }

    // MARK: - Left Page (Mon, Tue, Wed)

    private func leftPage(width: CGFloat, height: CGFloat) -> some View {
        let dayHeight = height / 3

        return VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                let dayDate = dayDate(for: index)
                DaySectionView(
                    date: dayDate,
                    data: binding(for: dayDate),
                    height: dayHeight,
                    onExpand: { onDayExpand(dayDate) },
                    onMeetingTap: onMeetingTap,
                    onTaskToggle: { task in toggleTask(task) },
                    onAddTask: { addQuickTask(for: dayDate) }
                )
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: - Right Page (Thu, Fri, Sat, Sun)

    private func rightPage(width: CGFloat, height: CGFloat) -> some View {
        let dayHeight = height / 4

        return VStack(spacing: 0) {
            ForEach(3..<7, id: \.self) { index in
                let dayDate = dayDate(for: index)
                DaySectionView(
                    date: dayDate,
                    data: binding(for: dayDate),
                    height: dayHeight,
                    onExpand: { onDayExpand(dayDate) },
                    onMeetingTap: onMeetingTap,
                    onTaskToggle: { task in toggleTask(task) },
                    onAddTask: { addQuickTask(for: dayDate) }
                )
            }
        }
        .frame(width: width, height: height)
    }

    // MARK: - Helpers

    private func dayDate(for dayIndex: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: dayIndex, to: weekStartDate)!
    }

    private func binding(for date: Date) -> DayData? {
        weekData[date.startOfDay]
    }

    private func toggleTask(_ task: DayTask) {
        task.isCompleted.toggle()
        try? modelContext.save()
        // Refresh
        loadWeekData()
    }

    private func addQuickTask(for date: Date) {
        let existingTasks = weekData[date.startOfDay]?.tasks ?? []
        let newTask = DayTask(
            title: "",
            date: date,
            sortOrder: existingTasks.count
        )
        modelContext.insert(newTask)
        try? modelContext.save()
        loadWeekData()
    }

    private func loadWeekData() {
        var data: [Date: DayData] = [:]

        for offset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: offset, to: weekStartDate)!
            let dayKey = date.startOfDay

            // Meetings
            let entries = appServices.meetingContextService.generateTimeline(
                for: date,
                context: modelContext
            )
            let meetings = entries.compactMap { $0.meetingRecord }

            // Notes
            let notes = appServices.meetingContextService.fetchNotesForDate(date, context: modelContext)

            // Tasks
            let taskDescriptor = FetchDescriptor<DayTask>(
                predicate: #Predicate { task in
                    task.date == dayKey
                },
                sortBy: [SortDescriptor(\.sortOrder)]
            )
            let tasks = (try? modelContext.fetch(taskDescriptor)) ?? []

            data[dayKey] = DayData(meetings: meetings, notes: notes, tasks: tasks)
        }

        weekData = data
    }
}

// MARK: - Page Corner Hint

private struct PageCornerHint: View {
    var body: some View {
        Canvas { context, size in
            let cornerSize: CGFloat = 24

            let shadowPath = Path { p in
                p.move(to: CGPoint(x: size.width, y: size.height - cornerSize))
                p.addLine(to: CGPoint(x: size.width - cornerSize, y: size.height))
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.closeSubpath()
            }
            context.fill(shadowPath, with: .color(.black.opacity(0.1)))

            let foldPath = Path { p in
                p.move(to: CGPoint(x: size.width - cornerSize + 2, y: size.height))
                p.addLine(to: CGPoint(x: size.width, y: size.height - cornerSize + 2))
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                p.closeSubpath()
            }
            context.fill(foldPath, with: .color(Color(white: 0.95)))
        }
        .frame(width: 30, height: 30)
        .allowsHitTesting(false)
    }
}

// MARK: - Day Section View

private struct DaySectionView: View {
    @Environment(\.theme) private var theme
    let date: Date
    let data: WeekSpreadView.DayData?
    let height: CGFloat
    let onExpand: () -> Void
    let onMeetingTap: (MeetingRecord) -> Void
    let onTaskToggle: (DayTask) -> Void
    let onAddTask: () -> Void

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day badge header
            HStack {
                dayBadge
                Spacer()
            }
            .padding(.leading, 8)
            .padding(.top, 6)

            // Content area with lines
            ZStack(alignment: .topLeading) {
                linedPaper
                contentOverlay
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .frame(height: height)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(theme.textures.paperLine.opacity(0.25))
                .frame(height: 0.5)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Day Badge

    private var dayBadge: some View {
        Button(action: onExpand) {
            HStack(spacing: 4) {
                Text(dayNumber)
                    .font(theme.typography.calendarDayNumber)

                Text(weekdayShort)
                    .font(theme.typography.calendarWeekday)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundStyle(isToday ? .white : theme.colors.textPrimary)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isToday ? Color.red : theme.colors.surface.opacity(0.8))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Lined Paper

    private var linedPaper: some View {
        let lineSpacing: CGFloat = 22
        let numberOfLines = max(0, Int((height - 34) / lineSpacing))

        return VStack(spacing: 0) {
            ForEach(0..<numberOfLines, id: \.self) { _ in
                Spacer()
                    .frame(height: lineSpacing - 0.5)
                Rectangle()
                    .fill(theme.textures.paperLine.opacity(theme.textures.paperLineOpacity * 0.6))
                    .frame(height: 0.5)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Content Overlay (Tasks + Meetings)

    private var contentOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Tasks first (with checkboxes)
            if let tasks = data?.tasks, !tasks.isEmpty {
                ForEach(tasks.prefix(2)) { task in
                    TaskRowView(task: task, onToggle: { onTaskToggle(task) })
                }
            }

            // Then meetings (if space)
            if let meetings = data?.meetings, !meetings.isEmpty {
                let tasksCount = data?.tasks.count ?? 0
                let showMeetings = tasksCount < 2
                if showMeetings {
                    ForEach(meetings.prefix(2 - tasksCount)) { meeting in
                        Button {
                            onMeetingTap(meeting)
                        } label: {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(theme.colors.accent)
                                    .frame(width: 5, height: 5)
                                Text(meeting.title)
                                    .font(theme.typography.calendarEventTitle)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .lineLimit(2)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return formatter.string(from: date)
    }
}

// MARK: - Task Row View (Checkbox + Title)

private struct TaskRowView: View {
    @Environment(\.theme) private var theme
    let task: DayTask
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                // Checkbox
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: theme.typography.calendarTaskCheckbox))
                    .foregroundStyle(task.isCompleted ? theme.colors.accent : theme.colors.textTertiary)

                // Title
                Text(task.title.isEmpty ? "New task" : task.title)
                    .font(theme.typography.calendarTaskTitle)
                    .foregroundStyle(task.isCompleted ? theme.colors.textTertiary : theme.colors.textPrimary)
                    .strikethrough(task.isCompleted, color: theme.colors.textTertiary)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
    }
}
