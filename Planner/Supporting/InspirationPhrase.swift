import Foundation

struct InspirationPhrase: Identifiable, Codable {
    let id: UUID
    let text: String
    let tone: Tone
    let generatedAt: Date

    enum Tone: String, Codable, CaseIterable {
        case warm
        case direct
        case reflective
    }

    enum Timing: String, Codable, CaseIterable {
        case morning
        case preMeeting
        case endOfDay
    }

    init(text: String, tone: Tone = .warm) {
        self.id = UUID()
        self.text = text
        self.tone = tone
        self.generatedAt = Date()
    }
}
