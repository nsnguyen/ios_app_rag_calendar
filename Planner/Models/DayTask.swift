import Foundation
import SwiftData

@Model
final class DayTask {
    var title: String
    var isCompleted: Bool
    var date: Date // The day this task belongs to (stored as start of day)
    var sortOrder: Int
    var createdAt: Date

    init(
        title: String,
        isCompleted: Bool = false,
        date: Date,
        sortOrder: Int = 0
    ) {
        self.title = title
        self.isCompleted = isCompleted
        self.date = date.startOfDay
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
