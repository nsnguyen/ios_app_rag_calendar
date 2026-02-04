import SwiftUI
import SwiftData

struct DayPageView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices

    let date: Date
    let onMeetingTap: (MeetingRecord) -> Void
    let onNoteTap: (Note) -> Void
    let onAddNote: () -> Void

    @State private var meetings: [MeetingRecord] = []
    @State private var tasks: [DayTask] = []
    @State private var inspirationPhrase: InspirationPhrase?
    @State private var newTaskTitle: String = ""
    @State private var isAddingTask: Bool = false
    @FocusState private var isTaskFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Day header
                dayHeader
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.md)

                // AI inspiration quote
                if let phrase = inspirationPhrase {
                    InspirationBannerView(phrase: phrase)
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.sm)
                }

                // Tasks section (full list)
                tasksSection
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.top, theme.spacing.lg)

                // All-day events
                if !allDayMeetings.isEmpty {
                    allDaySection
                        .padding(.horizontal, theme.spacing.lg)
                        .padding(.top, theme.spacing.md)
                }

                // Time slot grid
                TimeSlotGridView(
                    meetings: timedMeetings,
                    date: date,
                    onMeetingTap: onMeetingTap
                )
                .frame(height: 400)
                .padding(.leading, theme.spacing.sm)
                .padding(.top, theme.spacing.md)

                // Notes section
                LinkedNotesSection(
                    date: date,
                    onNoteTap: onNoteTap,
                    onAddNote: onAddNote
                )
                .padding(.horizontal, theme.spacing.lg)
                .padding(.vertical, theme.spacing.lg)
            }
        }
        .background(theme.textures.paperBase)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadData()
        }
    }

    // MARK: - Day Header

    private var dayHeader: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(weekdayString)
                .font(theme.typography.captionFont)
                .foregroundStyle(theme.colors.textSecondary)
                .textCase(.uppercase)
                .tracking(1.2)

            HStack(alignment: .firstTextBaseline, spacing: theme.spacing.sm) {
                Text(dayNumber)
                    .font(.system(size: 42, weight: .light, design: .serif))
                    .foregroundStyle(theme.colors.textPrimary)

                Text(monthString)
                    .font(theme.typography.headingFont)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            if isToday {
                Text("Today")
                    .font(theme.typography.captionFont)
                    .fontWeight(.medium)
                    .foregroundStyle(theme.colors.accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.sm) {
            // Header
            HStack {
                Label("Tasks", systemImage: "checkmark.circle")
                    .font(theme.typography.captionFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.textSecondary)

                Spacer()

                Button {
                    isAddingTask = true
                    isTaskFieldFocused = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                        .foregroundStyle(theme.colors.accent)
                }
            }

            // Task list
            VStack(spacing: theme.spacing.xs) {
                ForEach(tasks) { task in
                    DayTaskRowView(
                        task: task,
                        onToggle: { toggleTask(task) },
                        onDelete: { deleteTask(task) },
                        onUpdate: { newTitle in updateTask(task, title: newTitle) }
                    )
                }

                // Add task field
                if isAddingTask {
                    HStack(spacing: theme.spacing.sm) {
                        Image(systemName: "square")
                            .font(.system(size: 18))
                            .foregroundStyle(theme.colors.textTertiary)

                        TextField("New task...", text: $newTaskTitle)
                            .font(theme.typography.bodyFont)
                            .focused($isTaskFieldFocused)
                            .onSubmit {
                                addTask()
                            }

                        Button {
                            isAddingTask = false
                            newTaskTitle = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.colors.textTertiary)
                        }
                    }
                    .padding(.vertical, theme.spacing.xs)
                }
            }

            if tasks.isEmpty && !isAddingTask {
                Text("No tasks yet. Tap + to add one.")
                    .font(.caption)
                    .foregroundStyle(theme.colors.textTertiary)
                    .italic()
                    .padding(.vertical, theme.spacing.xs)
            }
        }
        .padding(theme.spacing.md)
        .background(theme.colors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
    }

    // MARK: - All Day Section

    private var allDaySection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Text("All Day")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(theme.colors.textTertiary)
                .textCase(.uppercase)

            ForEach(allDayMeetings) { meeting in
                Button {
                    onMeetingTap(meeting)
                } label: {
                    HStack(spacing: theme.spacing.sm) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.colors.accent)
                            .frame(width: 3, height: 16)

                        Text(meeting.title)
                            .font(theme.typography.captionFont)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.vertical, theme.spacing.xxs)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius / 2, style: .continuous))
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        date.formatted(as: .relative)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private var allDayMeetings: [MeetingRecord] {
        meetings.filter { $0.isAllDay }
    }

    private var timedMeetings: [MeetingRecord] {
        meetings.filter { !$0.isAllDay }
    }

    // MARK: - Task Actions

    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespaces).isEmpty else {
            isAddingTask = false
            newTaskTitle = ""
            return
        }

        let task = DayTask(
            title: newTaskTitle.trimmingCharacters(in: .whitespaces),
            date: date,
            sortOrder: tasks.count
        )
        modelContext.insert(task)
        try? modelContext.save()

        newTaskTitle = ""
        isAddingTask = false
        loadTasks()
    }

    private func toggleTask(_ task: DayTask) {
        task.isCompleted.toggle()
        try? modelContext.save()
    }

    private func deleteTask(_ task: DayTask) {
        modelContext.delete(task)
        try? modelContext.save()
        loadTasks()
    }

    private func updateTask(_ task: DayTask, title: String) {
        task.title = title
        try? modelContext.save()
    }

    // MARK: - Data Loading

    private func loadData() async {
        // Load meetings
        let entries = appServices.meetingContextService.generateTimeline(
            for: date,
            context: modelContext
        )
        meetings = entries.compactMap { $0.meetingRecord }

        // Load tasks
        loadTasks()

        // Load inspiration phrase
        let notes = fetchNotes()
        inspirationPhrase = await appServices.inspirationService.generatePhrase(
            meetings: meetings,
            notes: notes,
            tone: .warm
        )
    }

    private func loadTasks() {
        let dayKey = date.startOfDay
        let descriptor = FetchDescriptor<DayTask>(
            predicate: #Predicate { task in
                task.date == dayKey
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        tasks = (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchNotes() -> [Note] {
        let start = date.startOfDay
        let end = date.endOfDay
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.createdAt >= start && note.createdAt <= end
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Day Task Row View

private struct DayTaskRowView: View {
    @Environment(\.theme) private var theme
    let task: DayTask
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onUpdate: (String) -> Void

    @State private var isEditing = false
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(task.isCompleted ? theme.colors.accent : theme.colors.textTertiary)
            }

            // Title (editable)
            if isEditing {
                TextField("Task", text: $editText)
                    .font(theme.typography.bodyFont)
                    .focused($isFocused)
                    .onSubmit {
                        onUpdate(editText)
                        isEditing = false
                    }
            } else {
                Text(task.title)
                    .font(theme.typography.bodyFont)
                    .foregroundStyle(task.isCompleted ? theme.colors.textTertiary : theme.colors.textPrimary)
                    .strikethrough(task.isCompleted, color: theme.colors.textTertiary)
                    .onTapGesture {
                        editText = task.title
                        isEditing = true
                        isFocused = true
                    }
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(theme.colors.textTertiary)
            }
        }
        .padding(.vertical, theme.spacing.xs)
    }
}
