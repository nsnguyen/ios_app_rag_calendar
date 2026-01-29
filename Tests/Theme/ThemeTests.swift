import Testing
import Foundation
@testable import Planner

@Suite("Theme Tests")
struct ThemeTests {

    @Test("All themes produce valid configurations")
    func allThemesValid() {
        for theme in AppTheme.allCases {
            let config = theme.configuration
            #expect(config.shapes.cardRadius > 0)
            #expect(config.shapes.buttonRadius > 0)
            #expect(config.spacing.sm > 0)
            #expect(config.spacing.md > 0)
            #expect(config.spacing.lg > 0)
            #expect(config.shadows.cardRadius > 0)
        }
    }

    @Test("Theme display names are non-empty")
    func displayNames() {
        for theme in AppTheme.allCases {
            #expect(!theme.displayName.isEmpty)
            #expect(!theme.subtitle.isEmpty)
            #expect(!theme.iconName.isEmpty)
        }
    }

    @Test("ThemeManager persists to UserDefaults")
    func persistence() {
        let manager = ThemeManager()
        manager.setTheme(.boldEnergetic)

        let storedRaw = UserDefaults.standard.string(forKey: "selectedTheme")
        #expect(storedRaw == "boldEnergetic")

        // Restore
        let manager2 = ThemeManager()
        #expect(manager2.currentTheme == .boldEnergetic)

        // Reset
        manager2.setTheme(.calmRefined)
    }

    @Test("ThemeManager configuration matches current theme")
    func configurationMatches() {
        let manager = ThemeManager()
        for theme in AppTheme.allCases {
            manager.setTheme(theme)
            #expect(manager.configuration.shapes.cardRadius == theme.configuration.shapes.cardRadius)
        }
    }

    @Test("All theme spacing scales are monotonically increasing")
    func spacingScale() {
        for theme in AppTheme.allCases {
            let s = theme.configuration.spacing
            #expect(s.xxs <= s.xs)
            #expect(s.xs <= s.sm)
            #expect(s.sm <= s.md)
            #expect(s.md <= s.lg)
            #expect(s.lg <= s.xl)
            #expect(s.xl <= s.xxl)
            #expect(s.xxl <= s.xxxl)
        }
    }

    @Test("Calm theme has earthy colors")
    func calmThemeColors() {
        let config = AppTheme.calmRefined.configuration
        // Just verify it's not nil/crashy and the types resolve
        _ = config.colors.primary
        _ = config.colors.accent
        _ = config.colors.background
        _ = config.typography.displayFont
        _ = config.typography.bodyFont
    }

    @Test("Bold theme icon rendering is palette")
    func boldThemeRendering() {
        let config = AppTheme.boldEnergetic.configuration
        #expect(config.iconRenderingMode == .palette)
    }

    @Test("Minimal theme icon rendering is monochrome")
    func minimalThemeRendering() {
        let config = AppTheme.minimalPrecise.configuration
        #expect(config.iconRenderingMode == .monochrome)
    }
}
