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

    // Week range: ±52 weeks from current week
    private let weekRange = -52...52

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
            Text("Jump to Week")
                .font(theme.typography.headingFont)
                .padding(.top)

            // Quick navigation buttons
            HStack(spacing: theme.spacing.md) {
                Button("Today") {
                    currentWeekIndex = 0
                    showMonthPicker = false
                }
                .buttonStyle(.borderedProminent)

                Button("Next Week") {
                    currentWeekIndex += 1
                    showMonthPicker = false
                }
                .buttonStyle(.bordered)
            }

            Divider()

            // Month grid with event count badges
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: theme.spacing.sm) {
                ForEach(1...12, id: \.self) { month in
                    let count = eventCountForMonth(month)
                    Button {
                        jumpToMonth(month)
                        showMonthPicker = false
                    } label: {
                        VStack(spacing: 2) {
                            Text(monthAbbreviation(month))
                                .font(.system(size: 14, weight: .medium))

                            // Event density indicator
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
        .frame(width: 280)
        .presentationCompactAdaptation(.popover)
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

    private func jumpToMonth(_ month: Int) {
        let today = Date()
        var components = Calendar.current.dateComponents([.year], from: today)
        components.month = month
        components.day = 1

        let currentMonth = Calendar.current.component(.month, from: today)
        if month < currentMonth {
            components.year! += 1
        }

        if let targetDate = Calendar.current.date(from: components) {
            let todayStart = weekStartDate(for: 0)
            let days = Calendar.current.dateComponents([.day], from: todayStart, to: targetDate).day ?? 0
            currentWeekIndex = days / 7
        }
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
        return Calendar.current.component(.month, from: weekStart) == month
    }

    private func eventCountForMonth(_ month: Int) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
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
