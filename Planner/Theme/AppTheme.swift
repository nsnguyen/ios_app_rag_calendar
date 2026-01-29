import SwiftUI

/// The four distinct design themes available in Planner.
enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case calmRefined
    case boldEnergetic
    case warmOrganic
    case minimalPrecise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calmRefined: "Calm"
        case .boldEnergetic: "Bold"
        case .warmOrganic: "Warm"
        case .minimalPrecise: "Minimal"
        }
    }

    var subtitle: String {
        switch self {
        case .calmRefined: "Luxury journal"
        case .boldEnergetic: "Power tool"
        case .warmOrganic: "Cozy notebook"
        case .minimalPrecise: "Precision instrument"
        }
    }

    var iconName: String {
        switch self {
        case .calmRefined: "leaf.fill"
        case .boldEnergetic: "bolt.fill"
        case .warmOrganic: "sun.max.fill"
        case .minimalPrecise: "square.grid.2x2"
        }
    }

    var configuration: ThemeConfiguration {
        switch self {
        case .calmRefined: .calm
        case .boldEnergetic: .bold
        case .warmOrganic: .warm
        case .minimalPrecise: .minimal
        }
    }
}
