import SwiftUI

// MARK: - Theme Configuration

struct ThemeConfiguration: Sendable {
    let colors: ThemeColors
    let typography: ThemeTypography
    let spacing: ThemeSpacing
    let shapes: ThemeShapes
    let shadows: ThemeShadows
    let motion: ThemeMotion
    let iconRenderingMode: SymbolRenderingMode
    let textures: ThemeTextures
}

// MARK: - Theme Colors

struct ThemeColors: Sendable {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let card: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let border: Color
    let meetingCard: Color
    let noteHighlight: Color
    let tagBackground: Color
}

// MARK: - Theme Typography

struct ThemeTypography: Sendable {
    let displayFont: Font
    let headingFont: Font
    let bodyFont: Font
    let captionFont: Font
    let monoFont: Font
    let headingWeight: Font.Weight
    let bodyWeight: Font.Weight
    let letterSpacing: CGFloat

    // Calendar-specific typography for the week grid
    let calendarDayNumber: Font
    let calendarWeekday: Font
    let calendarEventTitle: Font
    let calendarTaskTitle: Font
    let calendarTaskCheckbox: CGFloat // size for SF Symbol

    static func charterFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Charter", size: size).weight(weight)
    }

    static func georgiaFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Georgia", size: size).weight(weight)
    }

    static func seravekFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Seravek", size: size).weight(weight)
    }

    static func roundedSystemFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Theme Spacing

struct ThemeSpacing: Sendable {
    let xxs: CGFloat  // 2
    let xs: CGFloat   // 4
    let sm: CGFloat   // 8
    let md: CGFloat   // 12
    let lg: CGFloat   // 16
    let xl: CGFloat   // 24
    let xxl: CGFloat  // 32
    let xxxl: CGFloat // 48
}

// MARK: - Theme Shapes

struct ThemeShapes: Sendable {
    let cardRadius: CGFloat
    let buttonRadius: CGFloat
    let chipRadius: CGFloat
    let sheetRadius: CGFloat
    let inputRadius: CGFloat
}

// MARK: - Theme Shadows

struct ThemeShadows: Sendable {
    let cardColor: Color
    let cardRadius: CGFloat
    let cardX: CGFloat
    let cardY: CGFloat

    let elevatedColor: Color
    let elevatedRadius: CGFloat
    let elevatedX: CGFloat
    let elevatedY: CGFloat

    let subtleColor: Color
    let subtleRadius: CGFloat
    let subtleX: CGFloat
    let subtleY: CGFloat
}

// MARK: - Theme Motion

struct ThemeMotion: Sendable {
    let defaultAnimation: Animation
    let springResponse: Double
    let springDamping: Double
    let staggerDelay: Double
    let transitionStyle: AnyTransition

    static let easeInOut = ThemeMotion(
        defaultAnimation: .easeInOut(duration: 0.35),
        springResponse: 0.5,
        springDamping: 0.85,
        staggerDelay: 0.06,
        transitionStyle: .opacity.combined(with: .scale(scale: 0.98))
    )

    static let bouncy = ThemeMotion(
        defaultAnimation: .spring(response: 0.4, dampingFraction: 0.7),
        springResponse: 0.4,
        springDamping: 0.7,
        staggerDelay: 0.04,
        transitionStyle: .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .opacity
        )
    )

    static let gentle = ThemeMotion(
        defaultAnimation: .easeInOut(duration: 0.4),
        springResponse: 0.55,
        springDamping: 0.8,
        staggerDelay: 0.07,
        transitionStyle: .opacity.combined(with: .move(edge: .bottom))
    )

    static let crisp = ThemeMotion(
        defaultAnimation: .easeOut(duration: 0.2),
        springResponse: 0.3,
        springDamping: 0.9,
        staggerDelay: 0.03,
        transitionStyle: .opacity
    )
}

// MARK: - Preset Configurations

extension ThemeConfiguration {
    static let calm = ThemeConfiguration(
        colors: ThemeColors(
            primary: Color(hex: "5B4F3E"),
            secondary: Color(hex: "8B7D6B"),
            accent: Color(hex: "6B8F71"),
            background: Color(hex: "F5F0EB"),
            surface: Color(hex: "FDFBF8"),
            card: Color(hex: "FFFFFF"),
            textPrimary: Color(hex: "2C2520"),
            textSecondary: Color(hex: "6B5F53"),
            textTertiary: Color(hex: "9E9185"),
            border: Color(hex: "E0D5C9"),
            meetingCard: Color(hex: "F8F4EF"),
            noteHighlight: Color(hex: "E8F0E4"),
            tagBackground: Color(hex: "6B8F71").opacity(0.15)
        ),
        typography: ThemeTypography(
            displayFont: ThemeTypography.charterFont(size: 28, weight: .bold),
            headingFont: ThemeTypography.charterFont(size: 20, weight: .semibold),
            bodyFont: ThemeTypography.charterFont(size: 16),
            captionFont: ThemeTypography.seravekFont(size: 13),
            monoFont: .system(size: 14, design: .monospaced),
            headingWeight: .semibold,
            bodyWeight: .regular,
            letterSpacing: 0.3,
            // Calm: elegant serif day numbers, refined labels
            calendarDayNumber: ThemeTypography.charterFont(size: 20, weight: .bold),
            calendarWeekday: ThemeTypography.seravekFont(size: 12, weight: .medium),
            calendarEventTitle: ThemeTypography.charterFont(size: 12, weight: .medium),
            calendarTaskTitle: ThemeTypography.seravekFont(size: 12, weight: .medium),
            calendarTaskCheckbox: 16
        ),
        spacing: ThemeSpacing(xxs: 2, xs: 6, sm: 10, md: 16, lg: 22, xl: 30, xxl: 40, xxxl: 56),
        shapes: ThemeShapes(cardRadius: 16, buttonRadius: 12, chipRadius: 20, sheetRadius: 24, inputRadius: 12),
        shadows: ThemeShadows(
            cardColor: Color(hex: "5B4F3E").opacity(0.08),
            cardRadius: 12, cardX: 0, cardY: 4,
            elevatedColor: Color(hex: "5B4F3E").opacity(0.15),
            elevatedRadius: 20, elevatedX: 0, elevatedY: 8,
            subtleColor: Color(hex: "5B4F3E").opacity(0.04),
            subtleRadius: 6, subtleX: 0, subtleY: 2
        ),
        motion: .easeInOut,
        iconRenderingMode: .hierarchical,
        textures: .calm
    )

    static let bold = ThemeConfiguration(
        colors: ThemeColors(
            primary: Color(hex: "E0E0FF"),
            secondary: Color(hex: "A0A0D0"),
            accent: Color(hex: "7B61FF"),
            background: Color(hex: "0F0F1A"),
            surface: Color(hex: "1A1A2E"),
            card: Color(hex: "222240"),
            textPrimary: Color(hex: "F0F0FF"),
            textSecondary: Color(hex: "B0B0D0"),
            textTertiary: Color(hex: "707090"),
            border: Color(hex: "333355"),
            meetingCard: Color(hex: "252545"),
            noteHighlight: Color(hex: "2A2A50"),
            tagBackground: Color(hex: "7B61FF").opacity(0.2)
        ),
        typography: ThemeTypography(
            displayFont: ThemeTypography.roundedSystemFont(size: 30, weight: .bold),
            headingFont: ThemeTypography.roundedSystemFont(size: 20, weight: .semibold),
            bodyFont: .system(size: 16),
            captionFont: .system(size: 13),
            monoFont: .system(size: 14, design: .monospaced),
            headingWeight: .bold,
            bodyWeight: .regular,
            letterSpacing: -0.2,
            // Bold: punchy rounded numbers, tight labels
            calendarDayNumber: ThemeTypography.roundedSystemFont(size: 22, weight: .heavy),
            calendarWeekday: ThemeTypography.roundedSystemFont(size: 12, weight: .semibold),
            calendarEventTitle: ThemeTypography.roundedSystemFont(size: 12, weight: .semibold),
            calendarTaskTitle: ThemeTypography.roundedSystemFont(size: 12, weight: .medium),
            calendarTaskCheckbox: 17
        ),
        spacing: ThemeSpacing(xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48),
        shapes: ThemeShapes(cardRadius: 12, buttonRadius: 10, chipRadius: 16, sheetRadius: 20, inputRadius: 10),
        shadows: ThemeShadows(
            cardColor: Color(hex: "7B61FF").opacity(0.12),
            cardRadius: 16, cardX: 0, cardY: 4,
            elevatedColor: Color(hex: "7B61FF").opacity(0.2),
            elevatedRadius: 24, elevatedX: 0, elevatedY: 8,
            subtleColor: Color(hex: "7B61FF").opacity(0.06),
            subtleRadius: 8, subtleX: 0, subtleY: 2
        ),
        motion: .bouncy,
        iconRenderingMode: .palette,
        textures: .bold
    )

    static let warm = ThemeConfiguration(
        colors: ThemeColors(
            primary: Color(hex: "8B4513"),
            secondary: Color(hex: "B8860B"),
            accent: Color(hex: "D2691E"),
            background: Color(hex: "FFF8F0"),
            surface: Color(hex: "FFFAF5"),
            card: Color(hex: "FFFFFF"),
            textPrimary: Color(hex: "3E2723"),
            textSecondary: Color(hex: "6D4C41"),
            textTertiary: Color(hex: "A1887F"),
            border: Color(hex: "EFDFCF"),
            meetingCard: Color(hex: "FFF3E6"),
            noteHighlight: Color(hex: "FFF0D0"),
            tagBackground: Color(hex: "D2691E").opacity(0.15)
        ),
        typography: ThemeTypography(
            displayFont: ThemeTypography.georgiaFont(size: 28, weight: .bold),
            headingFont: ThemeTypography.georgiaFont(size: 20, weight: .semibold),
            bodyFont: ThemeTypography.seravekFont(size: 16),
            captionFont: ThemeTypography.seravekFont(size: 13),
            monoFont: .system(size: 14, design: .monospaced),
            headingWeight: .semibold,
            bodyWeight: .regular,
            letterSpacing: 0.2,
            // Warm: handwritten-feel Georgia numbers, cozy Seravek labels
            calendarDayNumber: ThemeTypography.georgiaFont(size: 21, weight: .bold),
            calendarWeekday: ThemeTypography.seravekFont(size: 12, weight: .medium),
            calendarEventTitle: ThemeTypography.georgiaFont(size: 12, weight: .medium),
            calendarTaskTitle: ThemeTypography.seravekFont(size: 12, weight: .regular),
            calendarTaskCheckbox: 16
        ),
        spacing: ThemeSpacing(xxs: 3, xs: 6, sm: 10, md: 14, lg: 20, xl: 28, xxl: 38, xxxl: 52),
        shapes: ThemeShapes(cardRadius: 20, buttonRadius: 16, chipRadius: 24, sheetRadius: 28, inputRadius: 14),
        shadows: ThemeShadows(
            cardColor: Color(hex: "8B4513").opacity(0.1),
            cardRadius: 14, cardX: 0, cardY: 5,
            elevatedColor: Color(hex: "8B4513").opacity(0.16),
            elevatedRadius: 22, elevatedX: 0, elevatedY: 10,
            subtleColor: Color(hex: "8B4513").opacity(0.05),
            subtleRadius: 6, subtleX: 0, subtleY: 2
        ),
        motion: .gentle,
        iconRenderingMode: .multicolor,
        textures: .warm
    )

    static let minimal = ThemeConfiguration(
        colors: ThemeColors(
            primary: Color(.label),
            secondary: Color(.secondaryLabel),
            accent: Color(.tintColor),
            background: Color(.systemBackground),
            surface: Color(.secondarySystemBackground),
            card: Color(.tertiarySystemBackground),
            textPrimary: Color(.label),
            textSecondary: Color(.secondaryLabel),
            textTertiary: Color(.tertiaryLabel),
            border: Color(.separator),
            meetingCard: Color(.secondarySystemBackground),
            noteHighlight: Color(.systemYellow).opacity(0.1),
            tagBackground: Color(.tintColor).opacity(0.1)
        ),
        typography: ThemeTypography(
            displayFont: .system(size: 28, weight: .bold),
            headingFont: .system(size: 20, weight: .semibold),
            bodyFont: .system(size: 16),
            captionFont: .system(size: 13),
            monoFont: .system(size: 14, design: .monospaced),
            headingWeight: .semibold,
            bodyWeight: .regular,
            letterSpacing: 0,
            // Minimal: clean system fonts, precise weights
            calendarDayNumber: .system(size: 19, weight: .semibold),
            calendarWeekday: .system(size: 12, weight: .medium),
            calendarEventTitle: .system(size: 12, weight: .medium),
            calendarTaskTitle: .system(size: 12, weight: .regular),
            calendarTaskCheckbox: 16
        ),
        spacing: ThemeSpacing(xxs: 2, xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48),
        shapes: ThemeShapes(cardRadius: 10, buttonRadius: 8, chipRadius: 14, sheetRadius: 16, inputRadius: 8),
        shadows: ThemeShadows(
            cardColor: Color.black.opacity(0.06),
            cardRadius: 8, cardX: 0, cardY: 2,
            elevatedColor: Color.black.opacity(0.12),
            elevatedRadius: 16, elevatedX: 0, elevatedY: 6,
            subtleColor: Color.black.opacity(0.03),
            subtleRadius: 4, subtleX: 0, subtleY: 1
        ),
        motion: .crisp,
        iconRenderingMode: .monochrome,
        textures: .minimal
    )
}
