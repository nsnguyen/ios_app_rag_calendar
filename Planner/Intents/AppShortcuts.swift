import AppIntents

struct PlannerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowTodayIntent(),
            phrases: [
                "Show today in \(.applicationName)",
                "What meetings do I have in \(.applicationName)",
                "Open \(.applicationName)",
            ],
            shortTitle: "Today's Meetings",
            systemImageName: "calendar"
        )

        AppShortcut(
            intent: QueryMeetingIntent(),
            phrases: [
                "Search meetings in \(.applicationName)",
                "Find a meeting in \(.applicationName)",
                "Ask \(.applicationName) about meetings",
            ],
            shortTitle: "Search Meetings",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: SearchNotesIntent(),
            phrases: [
                "Search notes in \(.applicationName)",
                "Find notes in \(.applicationName)",
            ],
            shortTitle: "Search Notes",
            systemImageName: "note.text"
        )

        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "Add a note to \(.applicationName)",
            ],
            shortTitle: "Create Note",
            systemImageName: "plus"
        )
    }
}
