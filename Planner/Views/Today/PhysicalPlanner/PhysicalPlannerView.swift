import SwiftUI
import SwiftData

struct PhysicalPlannerView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices

    @State private var currentWeekIndex = 0 // 0 = current week
    @State private var showSettings = false
    @State private var showMonthPicker = false
    @State private var showNoteEditor = false
    @State private var selectedDayForExpand: Date?
    @State private var selectedNote: Note?
    @State private var showNoteEditorFromDay = false
    @State private var selectedPickerMonth: Int?
    @State private var selectedPickerYear: Int = Calendar.current.component(.year, from: Date())

    // Week range: ±3 years from current week
    private let weekRange = -156...156

    var body: some View {
        VStack(spacing: 0) {
            // Custom header (replaces navigation title)
            plannerHeader

            // Week spread with page curl
            PageCurlContainer(
                currentPageIndex: $currentWeekIndex,
                pageRange: weekRange
            ) { weekIndex in
                weekSpread(for: weekIndex)
            }
        }
        .background(Color.black) // Dark background around planner
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showNoteEditor) {
            NavigationStack {
                NoteEditorView()
            }
        }
        .fullScreenCover(item: $selectedDayForExpand) { date in
            NavigationStack {
                DayPageView(
                    date: date,
                    onMeetingTap: { _ in },
                    onNoteTap: { note in
                        selectedNote = note
                    },
                    onAddNote: {
                        showNoteEditorFromDay = true
                    }
                )
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            selectedDayForExpand = nil
                        }
                    }
                }
                .sheet(item: $selectedNote) { note in
                    NavigationStack {
                        NoteEditorView(note: note)
                    }
                }
                .sheet(isPresented: $showNoteEditorFromDay) {
                    NavigationStack {
                        NoteEditorView()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var plannerHeader: some View {
        HStack {
            // Month/Year and Week number
            Button {
                showMonthPicker = true
            } label: {
                HStack(spacing: theme.spacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 0) {
                        Text(monthYearString)
                            .font(.system(size: 15, weight: .semibold))
                        Text("Week \(weekNumber)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.md)
                .padding(.vertical, theme.spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.colors.surface)
                )
            }
            .popover(isPresented: $showMonthPicker) {
                monthPickerContent
            }

            Spacer()

            // Toolbar icons
            HStack(spacing: theme.spacing.md) {
                NavigationLink {
                    SearchView()
                } label: {
                    toolbarIcon("magnifyingglass")
                }

                Button {
                    showNoteEditor = true
                } label: {
                    toolbarIcon("note.text")
                }

                Button {
                    showSettings = true
                } label: {
                    toolbarIcon("gearshape")
                }
            }
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.background)
    }

    private func toolbarIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(theme.colors.textPrimary)
            .frame(width: 36, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.colors.surface)
            )
    }

    // MARK: - Week Spread

    private func weekSpread(for weekIndex: Int) -> some View {
        let weekStart = weekStartDate(for: weekIndex)
        return WeekSpreadView(
            weekStartDate: weekStart,
            onDayExpand: { date in
                selectedDayForExpand = date
            },
            onMeetingTap: { meeting in
                // Navigate to meeting detail
            }
        )
    }

    // MARK: - Month Picker

    private var monthPickerContent: some View {
        VStack(spacing: theme.spacing.md) {
            // Quick navigation buttons (always visible)
            HStack(spacing: theme.spacing.sm) {
                Button {
                    currentWeekIndex -= 1
                    showMonthPicker = false
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)

                Button("Today") {
                    currentWeekIndex = 0
                    showMonthPicker = false
                }
                .buttonStyle(.borderedProminent)

                Button {
                    currentWeekIndex += 1
                    showMonthPicker = false
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)

            Divider()

            // Two-step: month grid → week list
            if let month = selectedPickerMonth {
                weekListForMonth(month)
                    .transition(.move(edge: .trailing))
            } else {
                monthGrid
                    .transition(.move(edge: .leading))
            }
        }
        .frame(width: 280)
        .animation(.easeInOut(duration: 0.25), value: selectedPickerMonth)
        .presentationCompactAdaptation(.popover)
        .onChange(of: showMonthPicker) { _, isShowing in
            if !isShowing {
                selectedPickerMonth = nil
                selectedPickerYear = Calendar.current.component(.year, from: Date())
            }
        }
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        VStack(spacing: theme.spacing.sm) {
            // Year navigation
            HStack {
                Button {
                    selectedPickerYear -= 1
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                }

                Spacer()

                Text(String(selectedPickerYear))
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Button {
                    selectedPickerYear += 1
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: theme.spacing.sm) {
            ForEach(1...12, id: \.self) { month in
                let count = eventCountForMonth(month)
                Button {
                    selectedPickerMonth = month
                } label: {
                    VStack(spacing: 2) {
                        Text(monthAbbreviation(month))
                            .font(.system(size: 14, weight: .medium))

                        if count > 0 {
                            HStack(spacing: 2) {
                                ForEach(0..<min(count, 4), id: \.self) { _ in
                                    Circle()
                                        .fill(isCurrentMonth(month) ? .white.opacity(0.7) : theme.colors.accent.opacity(0.6))
                                        .frame(width: 4, height: 4)
                                }
                                if count > 4 {
                                    Text("+")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(isCurrentMonth(month) ? .white.opacity(0.7) : theme.colors.accent.opacity(0.6))
                                }
                            }
                            .frame(height: 6)
                        } else {
                            Spacer()
                                .frame(height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, theme.spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isCurrentMonth(month) ? theme.colors.accent : theme.colors.surface)
                    )
                    .foregroundStyle(isCurrentMonth(month) ? .white : theme.colors.textPrimary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
        }
    }

    // MARK: - Week List for Month

    private func weekListForMonth(_ month: Int) -> some View {
        VStack(spacing: theme.spacing.sm) {
            // Header with back button
            HStack {
                Button {
                    selectedPickerMonth = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 13))
                }

                Spacer()

                Text(monthFullName(month))
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                // Invisible spacer to center the title
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.system(size: 13))
                .hidden()
            }
            .padding(.horizontal)

            // Week rows
            VStack(spacing: theme.spacing.sm) {
                ForEach(weeksInMonth(month), id: \.start) { week in
                    weekRow(start: week.start, end: week.end)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func weekRow(start: Date, end: Date) -> some View {
        let count = eventCountForWeek(start: start, end: end)
        let isCurrent = isWeekCurrent(start: start)

        return Button {
            jumpToWeek(startingOn: start)
            showMonthPicker = false
        } label: {
            HStack {
                Text(weekDateRangeString(start: start, end: end))
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                if count > 0 {
                    Text("\(count) event\(count == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundStyle(isCurrent ? .white.opacity(0.7) : .secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(isCurrent ? .white.opacity(0.5) : theme.colors.textPrimary.opacity(0.3))
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrent ? theme.colors.accent : theme.colors.surface)
            )
            .foregroundStyle(isCurrent ? .white : theme.colors.textPrimary)
        }
    }

    // MARK: - Helpers

    private var monthYearString: String {
        let weekStart = weekStartDate(for: currentWeekIndex)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: weekStart)
    }

    private var weekNumber: Int {
        let weekStart = weekStartDate(for: currentWeekIndex)
        return Calendar.current.component(.weekOfYear, from: weekStart)
    }

    private func weekStartDate(for weekIndex: Int) -> Date {
        // Get Monday of current week
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        // weekday: 1 = Sunday, 2 = Monday, etc.
        // We want Monday as start, so offset to Monday
        let daysToMonday = (weekday == 1) ? -6 : (2 - weekday)
        let thisMonday = calendar.date(byAdding: .day, value: daysToMonday, to: today)!
        return calendar.date(byAdding: .weekOfYear, value: weekIndex, to: thisMonday)!
    }

    private func weeksInMonth(_ month: Int) -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        let year = selectedPickerYear

        guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) else {
            return []
        }

        // Find Monday of the week containing the 1st
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToMonday = (firstWeekday == 1) ? -6 : (2 - firstWeekday)
        var currentMonday = calendar.date(byAdding: .day, value: daysToMonday, to: firstOfMonth)!

        var weeks: [(start: Date, end: Date)] = []

        while currentMonday <= lastOfMonth {
            let sunday = calendar.date(byAdding: .day, value: 6, to: currentMonday)!
            weeks.append((start: currentMonday, end: sunday))
            currentMonday = calendar.date(byAdding: .day, value: 7, to: currentMonday)!
        }

        return weeks
    }

    private func weekDateRangeString(start: Date, end: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.component(.month, from: start) == calendar.component(.month, from: end) {
            formatter.dateFormat = "MMM d"
            let startStr = formatter.string(from: start)
            formatter.dateFormat = "d"
            let endStr = formatter.string(from: end)
            return "\(startStr) – \(endStr)"
        } else {
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        }
    }

    private func eventCountForWeek(start: Date, end: Date) -> Int {
        guard let weekEnd = Calendar.current.date(byAdding: .day, value: 1, to: end) else { return 0 }

        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { meeting in
                meeting.startDate >= start && meeting.startDate < weekEnd
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func jumpToWeek(startingOn monday: Date) {
        let calendar = Calendar.current
        let todayMonday = calendar.startOfDay(for: weekStartDate(for: 0))
        let targetMonday = calendar.startOfDay(for: monday)
        let days = calendar.dateComponents([.day], from: todayMonday, to: targetMonday).day ?? 0
        currentWeekIndex = days / 7
    }

    private func isWeekCurrent(start: Date) -> Bool {
        let currentStart = weekStartDate(for: currentWeekIndex)
        return Calendar.current.isDate(start, inSameDayAs: currentStart)
    }

    private func monthFullName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        let date = Calendar.current.date(from: components)!
        return formatter.string(from: date)
    }

    private func monthAbbreviation(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        var components = DateComponents()
        components.month = month
        let date = Calendar.current.date(from: components)!
        return formatter.string(from: date)
    }

    private func isCurrentMonth(_ month: Int) -> Bool {
        let weekStart = weekStartDate(for: currentWeekIndex)
        let calendar = Calendar.current
        return calendar.component(.month, from: weekStart) == month
            && calendar.component(.year, from: weekStart) == selectedPickerYear
    }

    private func eventCountForMonth(_ month: Int) -> Int {
        let calendar = Calendar.current
        let year = selectedPickerYear
        let startComponents = DateComponents(year: year, month: month, day: 1)
        guard let startDate = calendar.date(from: startComponents) else { return 0 }
        guard let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else { return 0 }

        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { meeting in
                meeting.startDate >= startDate && meeting.startDate < endDate
            }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}

// MARK: - Date Extension for Identifiable

extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
