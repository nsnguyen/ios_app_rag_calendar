import SwiftUI

struct ThemePickerView: View {
    @Environment(\.theme) private var theme
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        ScrollView {
            VStack(spacing: theme.spacing.lg) {
                Text("Choose your style")
                    .font(theme.typography.displayFont)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, theme.spacing.lg)

                ForEach(AppTheme.allCases) { appTheme in
                    ThemePreviewCard(
                        appTheme: appTheme,
                        isSelected: themeManager.currentTheme == appTheme
                    ) {
                        themeManager.setTheme(appTheme)
                    }
                    .padding(.horizontal, theme.spacing.lg)
                }
            }
            .padding(.vertical, theme.spacing.lg)
        }
        .background(theme.colors.background)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Theme Preview Card

private struct ThemePreviewCard: View {
    @Environment(\.theme) private var theme
    let appTheme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    private var previewConfig: ThemeConfiguration {
        appTheme.configuration
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    Image(systemName: appTheme.iconName)
                        .font(.title2)
                        .foregroundStyle(previewConfig.colors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appTheme.displayName)
                            .font(previewConfig.typography.headingFont)
                            .foregroundStyle(previewConfig.colors.textPrimary)
                        Text(appTheme.subtitle)
                            .font(previewConfig.typography.captionFont)
                            .foregroundStyle(previewConfig.colors.textSecondary)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(previewConfig.colors.accent)
                            .font(.title3)
                    }
                }

                // Color swatches preview
                HStack(spacing: theme.spacing.sm) {
                    colorSwatch(previewConfig.colors.primary, label: "Primary")
                    colorSwatch(previewConfig.colors.accent, label: "Accent")
                    colorSwatch(previewConfig.colors.secondary, label: "Secondary")
                    colorSwatch(previewConfig.colors.background, label: "Bg")
                }

                // Typography preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meeting with Design Team")
                        .font(previewConfig.typography.headingFont)
                        .foregroundStyle(previewConfig.colors.textPrimary)
                    Text("Today at 2:00 PM -- Conference Room A")
                        .font(previewConfig.typography.captionFont)
                        .foregroundStyle(previewConfig.colors.textSecondary)
                }
            }
            .padding(theme.spacing.lg)
            .background(previewConfig.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: previewConfig.shapes.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: previewConfig.shapes.cardRadius, style: .continuous)
                    .stroke(isSelected ? previewConfig.colors.accent : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: previewConfig.shadows.cardColor,
                radius: previewConfig.shadows.cardRadius,
                x: previewConfig.shadows.cardX,
                y: previewConfig.shadows.cardY
            )
        }
        .buttonStyle(.plain)
    }

    private func colorSwatch(_ color: Color, label: String) -> some View {
        VStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                )
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(theme.colors.textTertiary)
        }
    }
}
