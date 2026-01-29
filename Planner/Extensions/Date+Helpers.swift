import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    func formatted(as style: DateFormatStyle) -> String {
        switch style {
        case .time:
            self.formatted(date: .omitted, time: .shortened)
        case .shortDate:
            self.formatted(date: .abbreviated, time: .omitted)
        case .fullDate:
            self.formatted(date: .long, time: .omitted)
        case .dateTime:
            self.formatted(date: .abbreviated, time: .shortened)
        case .relative:
            relativeDescription
        }
    }

    enum DateFormatStyle {
        case time
        case shortDate
        case fullDate
        case dateTime
        case relative
    }

    private var relativeDescription: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }
        return self.formatted(date: .abbreviated, time: .omitted)
    }

    func daysFrom(_ other: Date) -> Int {
        Calendar.current.dateComponents([.day], from: other.startOfDay, to: self.startOfDay).day ?? 0
    }

    static func dateRange(from start: Date, to end: Date) -> [Date] {
        var dates: [Date] = []
        var current = start.startOfDay
        let endDay = end.startOfDay
        while current <= endDay {
            dates.append(current)
            current = Calendar.current.date(byAdding: .day, value: 1, to: current)!
        }
        return dates
    }
}
