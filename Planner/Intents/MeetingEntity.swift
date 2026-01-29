import AppIntents
import Foundation
import SwiftData

struct MeetingEntity: AppEntity {
    static var defaultQuery = MeetingEntityQuery()
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Meeting")

    var id: String
    var title: String
    var startDate: Date
    var location: String?

    var displayRepresentation: DisplayRepresentation {
        let subtitle: String
        if let location, !location.isEmpty {
            subtitle = "\(startDate.formatted(date: .abbreviated, time: .shortened)) -- \(location)"
        } else {
            subtitle = startDate.formatted(date: .abbreviated, time: .shortened)
        }
        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)"
        )
    }

    init(from meeting: MeetingRecord) {
        self.id = meeting.eventIdentifier
        self.title = meeting.title
        self.startDate = meeting.startDate
        self.location = meeting.location
    }
}

struct MeetingEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MeetingEntity] {
        let context = ModelContext(SharedModelContainer.shared)
        return identifiers.compactMap { id in
            let descriptor = FetchDescriptor<MeetingRecord>(
                predicate: #Predicate { $0.eventIdentifier == id }
            )
            guard let meeting = try? context.fetch(descriptor).first else { return nil }
            return MeetingEntity(from: meeting)
        }
    }

    func suggestedEntities() async throws -> [MeetingEntity] {
        let context = ModelContext(SharedModelContainer.shared)
        var descriptor = FetchDescriptor<MeetingRecord>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        let meetings = (try? context.fetch(descriptor)) ?? []
        return meetings.map { MeetingEntity(from: $0) }
    }
}
