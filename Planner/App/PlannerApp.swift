import SwiftUI
import SwiftData

@main
struct PlannerApp: App {
    @State private var themeManager = ThemeManager()
    @State private var appServices = AppServices()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
                .environment(appServices)
                .themed(with: themeManager)
                .task {
                    let context = ModelContext(SharedModelContainer.shared)
                    appServices.meetingContextService.startBackgroundSync(context: context)
                }
        }
        .modelContainer(SharedModelContainer.shared)
    }
}
