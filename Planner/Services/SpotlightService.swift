import CoreSpotlight
import Foundation
import SwiftData

protocol SpotlightServiceProtocol: Sendable {
    func indexMeeting(_ meeting: MeetingRecord)
    func indexNote(_ note: Note)
    func removeFromIndex(identifier: String)
}

final class SpotlightService: SpotlightServiceProtocol, @unchecked Sendable {
    private let searchableIndex: CSSearchableIndex

    init(index: CSSearchableIndex = .default()) {
        self.searchableIndex = index
    }

    func indexMeeting(_ meeting: MeetingRecord) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = meeting.title
        attributeSet.contentDescription = [
            meeting.location,
            meeting.purpose,
            meeting.outcomes,
        ].compactMap { $0 }.joined(separator: " -- ")
        attributeSet.startDate = meeting.startDate
        attributeSet.endDate = meeting.endDate

        if !meeting.attendees.isEmpty {
            attributeSet.authorNames = meeting.attendees.map(\.name)
        }

        let item = CSSearchableItem(
            uniqueIdentifier: "meeting:\(meeting.eventIdentifier)",
            domainIdentifier: "com.planner.meetings",
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())

        searchableIndex.indexSearchableItems([item])
    }

    func indexNote(_ note: Note) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
        attributeSet.title = note.title.isEmpty ? "Untitled Note" : note.title
        attributeSet.contentDescription = String(note.plainText.prefix(500))

        let identifier = note.persistentModelID.hashValue
        let item = CSSearchableItem(
            uniqueIdentifier: "note:\(identifier)",
            domainIdentifier: "com.planner.notes",
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())

        searchableIndex.indexSearchableItems([item])
    }

    func removeFromIndex(identifier: String) {
        searchableIndex.deleteSearchableItems(withIdentifiers: [identifier])
    }
}
