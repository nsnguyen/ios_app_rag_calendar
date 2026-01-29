import SwiftUI

struct InspirationBannerView: View {
    @Environment(\.theme) private var theme
    let phrase: InspirationPhrase

    var body: some View {
        HStack(spacing: theme.spacing.md) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(theme.colors.accent)
                .symbolRenderingMode(theme.iconRenderingMode)

            Text(phrase.text)
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textPrimary)
                .italic()
                .lineLimit(3)
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
        .shadow(
            color: theme.shadows.subtleColor,
            radius: theme.shadows.subtleRadius,
            x: theme.shadows.subtleX,
            y: theme.shadows.subtleY
        )
    }
}
