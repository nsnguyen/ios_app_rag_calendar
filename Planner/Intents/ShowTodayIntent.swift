import AppIntents
import Foundation
import SwiftData

struct ShowTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today"
    static var description: IntentDescription = "Open Planner to see today's meetings."

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(SharedModelContainer.shared)
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay)!

        let descriptor = FetchDescriptor<MeetingRecord>(
            predicate: #Predicate { meeting in
                meeting.startDate >= startOfDay && meeting.startDate <= endOfDay
            }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0

        if count == 0 {
            return .result(dialog: "Your schedule is clear today.")
        } else {
            return .result(dialog: "You have \(count) meeting(s) today.")
        }
    }
}
