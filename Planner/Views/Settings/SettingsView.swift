import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ThemePickerView()
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Appearance")
                                Text(themeManager.currentTheme.displayName)
                                    .font(theme.typography.captionFont)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        } icon: {
                            Image(systemName: "paintbrush")
                        }
                    }
                } header: {
                    Text("Personalization")
                }

                Section {
                    NavigationLink {
                        InspirationSettingsView()
                    } label: {
                        Label("Inspiration", systemImage: "sparkles")
                    }
                } header: {
                    Text("Features")
                }

                Section {
                    NavigationLink {
                        PermissionsSettingsView()
                    } label: {
                        Label("Permissions", systemImage: "lock.shield")
                    }
                } header: {
                    Text("Privacy")
                }

                Section {
                    NavigationLink {
                        DataSettingsView()
                    } label: {
                        Label("Data & Storage", systemImage: "externaldrive")
                    }
                } header: {
                    Text("Data")
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(theme.colors.textTertiary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
