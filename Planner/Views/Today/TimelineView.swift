import SwiftUI
import SwiftData

struct TimelineView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppServices.self) private var appServices
    @State private var selectedDate = Date()
    @State private var entries: [TimelineEntry] = []
    @State private var inspirationPhrase: InspirationPhrase?
    @State private var showSettings = false
    @State private var datesWithMeetings: Set<String> = []
    @State private var isMonthViewExpanded = false
    @State private var displayedMonth = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                if let phrase = inspirationPhrase {
                    InspirationBannerView(phrase: phrase)
                        .padding(.horizontal, theme.spacing.lg)
                }

                calendarSection

                if entries.isEmpty {
                    EmptyStateView(
                        title: "No Meetings",
                        systemImage: "calendar.badge.checkmark",
                        description: "Your schedule is clear for \(selectedDate.formatted(as: .relative))."
                    )
                    .padding(.top, theme.spacing.xxxl)
                } else {
                    LazyVStack(spacing: theme.spacing.md) {
                        ForEach(entries) { entry in
                            NavigationLink(value: entry.meetingRecord) {
                                MeetingCardView(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
            }
            .padding(.vertical, theme.spacing.md)
        }
        .background(theme.colors.background)
        .navigationTitle(selectedDate.formatted(as: .relative))
        .navigationDestination(for: MeetingRecord.self) { meeting in
            MeetingDetailView(meeting: meeting)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .symbolRenderingMode(theme.iconRenderingMode)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .task {
            await loadTimeline()
        }
        .onChange(of: selectedDate) {
            Task { await loadTimeline() }
        }
        .onChange(of: isMonthViewExpanded) {
            loadMeetingIndicators()
        }
        .onChange(of: displayedMonth) {
            loadMeetingIndicators()
        }
    }

    private var calendarSection: some View {
        VStack(spacing: theme.spacing.sm) {
            // Month/Year header with toggle
            calendarHeader

            if isMonthViewExpanded {
                monthCalendarView
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            } else {
                weekStripView
                    .transition(.asymmetric(
                        insertion: .push(from: .bottom).combined(with: .opacity),
                        removal: .push(from: .top).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isMonthViewExpanded)
    }

    private var calendarHeader: some View {
        HStack {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(theme.typography.bodyFont.weight(.semibold))
                    .foregroundStyle(theme.colors.accent)
            }
            .opacity(isMonthViewExpanded ? 1 : 0)
            .disabled(!isMonthViewExpanded)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isMonthViewExpanded.toggle()
                }
            } label: {
                HStack(spacing: theme.spacing.xs) {
                    Text(monthYearString)
                        .font(theme.typography.bodyFont.weight(.semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                    Image(systemName: isMonthViewExpanded ? "chevron.up" : "chevron.down")
                        .font(theme.typography.captionFont.weight(.semibold))
                        .foregroundStyle(theme.colors.accent)
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(theme.typography.bodyFont.weight(.semibold))
                    .foregroundStyle(theme.colors.accent)
            }
            .opacity(isMonthViewExpanded ? 1 : 0)
            .disabled(!isMonthViewExpanded)
        }
        .padding(.horizontal, theme.spacing.lg)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: isMonthViewExpanded ? displayedMonth : selectedDate)
    }

    private var weekStripView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.sm) {
                ForEach(-3..<7, id: \.self) { offset in
                    let date = Calendar.current.date(byAdding: .day, value: offset, to: Date().startOfDay)!
                    let key = Self.dayKey(for: date)
                    DateChipView(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        hasMeetings: datesWithMeetings.contains(key)
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, theme.spacing.lg)
        }
    }

    private var monthCalendarView: some View {
        VStack(spacing: theme.spacing.sm) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(theme.typography.captionFont)
                        .foregroundStyle(theme.colors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, theme.spacing.md)

            // Calendar grid
            let days = daysInMonth
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: theme.spacing.xs) {
                ForEach(days, id: \.self) { day in
                    if let date = day {
                        let key = Self.dayKey(for: date)
                        MonthDayView(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: Calendar.current.isDateInToday(date),
                            hasMeetings: datesWithMeetings.contains(key)
                        ) {
                            selectedDate = date
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                isMonthViewExpanded = false
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal, theme.spacing.md)
        }
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
        .padding(.horizontal, theme.spacing.lg)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }

    private var daysInMonth: [Date?] {
        let calendar = Calendar.current
        let interval = calendar.dateInterval(of: .month, for: displayedMonth)!
        let firstOfMonth = interval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count

        var days: [Date?] = []

        // Add empty slots for days before the first of the month
        let emptySlots = (firstWeekday - calendar.firstWeekday + 7) % 7
        for _ in 0..<emptySlots {
            days.append(nil)
        }

        // Add all days in the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(components.year!)-\(components.month!)-\(components.day!)"
    }

    private func loadTimeline() async {
        entries = appServices.meetingContextService.generateTimeline(
            for: selectedDate,
            context: modelContext
        )

        // Load meeting indicators for all visible date chips
        loadMeetingIndicators()

        // Load inspiration phrase
        let tone: InspirationPhrase.Tone = .warm
        let todayMeetings = entries.compactMap(\.meetingRecord)
        let noteDescriptor = FetchDescriptor<Note>()
        let notes = (try? modelContext.fetch(noteDescriptor)) ?? []
        inspirationPhrase = await appServices.inspirationService.generatePhrase(
            meetings: todayMeetings,
            notes: notes,
            tone: tone
        )
    }

    private func loadMeetingIndicators() {
        let calendar = Calendar.current
        let rangeStart: Date
        let rangeEnd: Date

        if isMonthViewExpanded {
            // Load for entire displayed month
            let interval = calendar.dateInterval(of: .month, for: displayedMonth)!
            rangeStart = interval.start
            rangeEnd = interval.end
        } else {
            // Load for week strip range
            let today = Date().startOfDay
            rangeStart = calendar.date(byAdding: .day, value: -3, to: today)!
            rangeEnd = calendar.date(byAdding: .day, value: 7, to: today)!
        }

        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { meeting in
                meeting.startDate >= rangeStart && meeting.startDate <= rangeEnd
            }
        )
        guard let meetings = try? modelContext.fetch(descriptor) else { return }
        var keys = Set<String>()
        for meeting in meetings {
            keys.insert(Self.dayKey(for: meeting.startDate))
        }
        datesWithMeetings = keys
    }
}

// MARK: - Date Chip

private struct DateChipView: View {
    @Environment(\.theme) private var theme
    let date: Date
    let isSelected: Bool
    var hasMeetings: Bool = false
    let action: () -> Void

    // MARK: - Static DateFormatters (cached)

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacing.xxs) {
                Text(dayOfWeek)
                    .font(theme.typography.captionFont)
                    .foregroundStyle(isSelected ? theme.colors.card : theme.colors.textSecondary)
                Text(dayNumber)
                    .font(theme.typography.headingFont)
                    .foregroundStyle(isSelected ? theme.colors.card : theme.colors.textPrimary)
                if hasMeetings {
                    Circle()
                        .fill(isSelected ? theme.colors.card : theme.colors.accent)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.sm)
            .background(isSelected ? theme.colors.accent : theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.chipRadius, style: .continuous))
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var dayOfWeek: String {
        Self.weekdayFormatter.string(from: date)
    }

    private var dayNumber: String {
        Self.dayFormatter.string(from: date)
    }

    private var accessibilityDescription: String {
        var description = Self.accessibilityFormatter.string(from: date)
        if isSelected {
            description += ", selected"
        }
        if hasMeetings {
            description += ", has meetings"
        }
        return description
    }
}

// MARK: - Month Day View

private struct MonthDayView: View {
    @Environment(\.theme) private var theme
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    var hasMeetings: Bool = false
    let action: () -> Void

    // MARK: - Static DateFormatters (cached)

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let accessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(theme.typography.bodyFont.weight(isToday ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
                    .frame(width: 36, height: 36)
                    .background(backgroundColor)
                    .clipShape(Circle())
                if hasMeetings {
                    Circle()
                        .fill(isSelected ? theme.colors.card : theme.colors.accent)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var dayNumber: String {
        Self.dayFormatter.string(from: date)
    }

    private var foregroundColor: Color {
        if isSelected {
            return theme.colors.card
        } else if isToday {
            return theme.colors.accent
        } else {
            return theme.colors.textPrimary
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return theme.colors.accent
        } else if isToday {
            return theme.colors.accent.opacity(0.15)
        } else {
            return .clear
        }
    }

    private var accessibilityDescription: String {
        var description = Self.accessibilityFormatter.string(from: date)
        if isSelected {
            description += ", selected"
        }
        if isToday {
            description += ", today"
        }
        if hasMeetings {
            description += ", has meetings"
        }
        return description
    }
}
