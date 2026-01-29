import SwiftUI
import EventKit

struct PermissionsSettingsView: View {
    @Environment(\.theme) private var theme
    @State private var calendarStatus: CalendarAuthorizationStatus = .notDetermined
    @State private var isRequesting = false

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Calendar", systemImage: "calendar")
                    Spacer()
                    statusBadge(for: calendarStatus)
                }

                if calendarStatus == .notDetermined {
                    Button("Grant Calendar Access") {
                        requestCalendarAccess()
                    }
                } else if calendarStatus == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            } header: {
                Text("Calendar")
            } footer: {
                Text("Planner reads your calendar to show meetings and help you prepare for them. No data leaves your device.")
            }

            Section {
                HStack {
                    Label("Siri", systemImage: "mic")
                    Spacer()
                    Text("Configured")
                        .font(theme.typography.captionFont)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            } header: {
                Text("Siri & Shortcuts")
            } footer: {
                Text("Use Siri to ask about your meetings and notes hands-free.")
            }
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            calendarStatus = CalendarAuthorizationStatus(
                from: EKEventStore.authorizationStatus(for: .event)
            )
        }
    }

    @ViewBuilder
    private func statusBadge(for status: CalendarAuthorizationStatus) -> some View {
        switch status {
        case .fullAccess:
            Label("Granted", systemImage: "checkmark.circle.fill")
                .font(theme.typography.captionFont)
                .foregroundStyle(.green)
        case .denied, .restricted:
            Label("Denied", systemImage: "xmark.circle.fill")
                .font(theme.typography.captionFont)
                .foregroundStyle(.red)
        case .notDetermined:
            Text("Not Set")
                .font(theme.typography.captionFont)
                .foregroundStyle(theme.colors.textTertiary)
        case .writeOnly:
            Label("Write Only", systemImage: "exclamationmark.circle.fill")
                .font(theme.typography.captionFont)
                .foregroundStyle(.orange)
        }
    }

    private func requestCalendarAccess() {
        isRequesting = true
        Task {
            let service = CalendarService()
            _ = try? await service.requestAccess()
            calendarStatus = CalendarAuthorizationStatus(
                from: EKEventStore.authorizationStatus(for: .event)
            )
            isRequesting = false
        }
    }
}
