import SwiftUI

struct TagChipView: View {
    @Environment(\.theme) private var theme
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Color(hex: tag.color))
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xxs)
            .background(Color(hex: tag.color).opacity(0.15))
            .clipShape(Capsule())
    }
}
