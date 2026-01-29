import SwiftUI

// MARK: - Environment Key

private struct ThemeConfigurationKey: EnvironmentKey {
    static let defaultValue: ThemeConfiguration = .calm
}

extension EnvironmentValues {
    var theme: ThemeConfiguration {
        get { self[ThemeConfigurationKey.self] }
        set { self[ThemeConfigurationKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Applies the current theme configuration from ThemeManager to the environment.
    func themed(with manager: ThemeManager) -> some View {
        self.environment(\.theme, manager.configuration)
    }
}
