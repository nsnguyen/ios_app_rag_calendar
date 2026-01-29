import SwiftUI

struct ContentView: View {
    @Environment(\.theme) private var theme
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if shouldShowOnboarding {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
            mainTabView
        }
    }

    private var shouldShowOnboarding: Bool {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--skip-onboarding") { return false }
        if args.contains("--reset-onboarding") { return true }
        return !hasCompletedOnboarding
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "calendar", value: 0) {
                NavigationStack {
                    TimelineView()
                }
            }

            Tab("Notes", systemImage: "note.text", value: 1) {
                NavigationStack {
                    NotesListView()
                }
            }

            Tab("Search", systemImage: "magnifyingglass", value: 2) {
                NavigationStack {
                    SearchView()
                }
            }

            Tab("People", systemImage: "person.2", value: 3) {
                NavigationStack {
                    PeopleView()
                }
            }
        }
        .tint(theme.colors.accent)
    }
}
