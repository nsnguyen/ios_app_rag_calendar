import SwiftUI
import EventKit

struct OnboardingView: View {
    @Environment(\.theme) private var theme
    @Environment(ThemeManager.self) private var themeManager
    @State private var currentStep = 0
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        TabView(selection: $currentStep) {
            welcomeStep.tag(0)
            themeStep.tag(1)
            calendarStep.tag(2)
            siriStep.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .background(theme.colors.background.ignoresSafeArea())
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 72))
                .foregroundStyle(theme.colors.accent)
                .symbolRenderingMode(theme.iconRenderingMode)

            Text("Welcome to Planner")
                .font(theme.typography.displayFont)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Your intelligent daily planner with AI memory.")
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xxl)

            Spacer()

            Button {
                withAnimation { currentStep = 1 }
            } label: {
                Text("Get Started")
                    .font(theme.typography.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.card)
                    .frame(maxWidth: .infinity)
                    .padding(theme.spacing.lg)
                    .background(theme.colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: theme.shapes.buttonRadius, style: .continuous))
            }
            .padding(.horizontal, theme.spacing.xl)
            .padding(.bottom, theme.spacing.xxl)
        }
    }

    // MARK: - Theme Selection

    private var themeStep: some View {
        VStack(spacing: theme.spacing.lg) {
            Text("Choose Your Style")
                .font(theme.typography.displayFont)
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.top, theme.spacing.xl)

            ScrollView {
                VStack(spacing: theme.spacing.md) {
                    ForEach(AppTheme.allCases) { appTheme in
                        OnboardingThemeRow(
                            appTheme: appTheme,
                            isSelected: themeManager.currentTheme == appTheme
                        ) {
                            themeManager.setTheme(appTheme)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.lg)
            }

            Button {
                withAnimation { currentStep = 2 }
            } label: {
                Text("Continue")
                    .font(theme.typography.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.colors.card)
                    .frame(maxWidth: .infinity)
                    .padding(theme.spacing.lg)
                    .background(theme.colors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: theme.shapes.buttonRadius, style: .continuous))
            }
            .padding(.horizontal, theme.spacing.xl)
            .padding(.bottom, theme.spacing.lg)
        }
    }

    // MARK: - Calendar Permission

    private var calendarStep: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 60))
                .foregroundStyle(theme.colors.accent)
                .symbolRenderingMode(theme.iconRenderingMode)

            Text("Calendar Access")
                .font(theme.typography.displayFont)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Planner reads your calendar to show meetings and help you prepare. All data stays on your device.")
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xxl)

            Spacer()

            VStack(spacing: theme.spacing.md) {
                Button {
                    requestCalendarAccess()
                } label: {
                    Text("Allow Calendar Access")
                        .font(theme.typography.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.colors.card)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.lg)
                        .background(theme.colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.buttonRadius, style: .continuous))
                }

                Button {
                    withAnimation { currentStep = 3 }
                } label: {
                    Text("Maybe Later")
                        .font(theme.typography.captionFont)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(.horizontal, theme.spacing.xl)
            .padding(.bottom, theme.spacing.xxl)
        }
    }

    // MARK: - Siri Permission

    private var siriStep: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.colors.accent)
                .symbolRenderingMode(theme.iconRenderingMode)

            Text("Siri Integration")
                .font(theme.typography.displayFont)
                .foregroundStyle(theme.colors.textPrimary)

            Text("Ask Siri about your meetings and notes. \"What meetings do I have today?\"")
                .font(theme.typography.bodyFont)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, theme.spacing.xxl)

            Spacer()

            VStack(spacing: theme.spacing.md) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Done")
                        .font(theme.typography.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.colors.card)
                        .frame(maxWidth: .infinity)
                        .padding(theme.spacing.lg)
                        .background(theme.colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: theme.shapes.buttonRadius, style: .continuous))
                }
            }
            .padding(.horizontal, theme.spacing.xl)
            .padding(.bottom, theme.spacing.xxl)
        }
    }

    // MARK: - Actions

    private func requestCalendarAccess() {
        Task {
            let service = CalendarService()
            _ = try? await service.requestAccess()
            withAnimation { currentStep = 3 }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Theme Row

private struct OnboardingThemeRow: View {
    @Environment(\.theme) private var theme
    let appTheme: AppTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: theme.spacing.md) {
                Image(systemName: appTheme.iconName)
                    .font(.title3)
                    .foregroundStyle(appTheme.configuration.colors.accent)
                    .frame(width: 36)

                VStack(alignment: .leading) {
                    Text(appTheme.displayName)
                        .font(theme.typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.colors.textPrimary)
                    Text(appTheme.subtitle)
                        .font(theme.typography.captionFont)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.colors.accent)
                }
            }
            .padding(theme.spacing.md)
            .background(isSelected ? theme.colors.surface : theme.colors.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.shapes.cardRadius, style: .continuous)
                    .stroke(isSelected ? theme.colors.accent : theme.colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
