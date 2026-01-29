import SwiftUI

struct ThemedBackground: View {
    @Environment(\.theme) private var theme

    var body: some View {
        theme.colors.background
            .ignoresSafeArea()
    }
}

struct ThemedBackgroundModifier: ViewModifier {
    @Environment(\.theme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.colors.background.ignoresSafeArea())
    }
}

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
}
