import SwiftUI

// MARK: - Themed Card

struct ThemedCardModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.lg)
            .background(theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
            .shadow(
                color: theme.shadows.cardColor,
                radius: theme.shadows.cardRadius,
                x: theme.shadows.cardX,
                y: theme.shadows.cardY
            )
    }
}

// MARK: - Themed Heading

struct ThemedHeadingModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.headingFont)
            .fontWeight(theme.typography.headingWeight)
            .foregroundStyle(theme.colors.textPrimary)
            .tracking(theme.typography.letterSpacing)
    }
}

// MARK: - Themed Body

struct ThemedBodyModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.bodyFont)
            .fontWeight(theme.typography.bodyWeight)
            .foregroundStyle(theme.colors.textPrimary)
    }
}

// MARK: - Themed Caption

struct ThemedCaptionModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .font(theme.typography.captionFont)
            .foregroundStyle(theme.colors.textSecondary)
    }
}

// MARK: - Themed Surface

struct ThemedSurfaceModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .padding(theme.spacing.md)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.inputRadius, style: .continuous))
    }
}

// MARK: - View Extensions

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func themedHeading() -> some View {
        modifier(ThemedHeadingModifier())
    }

    func themedBody() -> some View {
        modifier(ThemedBodyModifier())
    }

    func themedCaption() -> some View {
        modifier(ThemedCaptionModifier())
    }

    func themedSurface() -> some View {
        modifier(ThemedSurfaceModifier())
    }
}
