import Foundation
import SwiftData

/// Provides a shared ModelContainer for use in App Intents and other
/// process-isolated contexts where @Environment is unavailable.
@MainActor
enum SharedModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            MeetingRecord.self,
            Note.self,
            Person.self,
            EmbeddingRecord.self,
            Tag.self,
            DayTask.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: PlannerMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
