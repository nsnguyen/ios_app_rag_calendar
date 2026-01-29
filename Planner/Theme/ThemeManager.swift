import SwiftUI

@Observable
final class ThemeManager {
    private static let storageKey = "selectedTheme"

    var currentTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: Self.storageKey)
        }
    }

    var configuration: ThemeConfiguration {
        currentTheme.configuration
    }

    init() {
        if let stored = UserDefaults.standard.string(forKey: Self.storageKey),
           let theme = AppTheme(rawValue: stored) {
            self.currentTheme = theme
        } else {
            self.currentTheme = .calmRefined
        }
    }

    func setTheme(_ theme: AppTheme) {
        withAnimation(currentTheme.configuration.motion.defaultAnimation) {
            currentTheme = theme
        }
    }
}
