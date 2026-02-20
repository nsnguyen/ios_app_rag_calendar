import SwiftUI

struct ContentView: View {
    @Environment(\.theme) private var theme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Handle test launch arguments
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--reset-onboarding") {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
    }

    var body: some View {
        if shouldShowOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            NavigationStack {
                PhysicalPlannerView()
            }
            .tint(theme.colors.accent)
        }
    }

    private var shouldShowOnboarding: Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--skip-onboarding") { return false }
        return !hasCompletedOnboarding
    }
}
