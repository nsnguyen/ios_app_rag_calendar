import SwiftUI

struct EmptyStateView: View {
    @Environment(\.theme) private var theme
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
                .foregroundStyle(theme.colors.textSecondary)
        } description: {
            Text(description)
                .font(theme.typography.captionFont)
                .foregroundStyle(theme.colors.textTertiary)
        }
    }
}
