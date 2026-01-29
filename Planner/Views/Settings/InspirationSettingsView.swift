import SwiftUI

struct InspirationSettingsView: View {
    @Environment(\.theme) private var theme
    @AppStorage("inspirationTone") private var tone = InspirationPhrase.Tone.warm.rawValue
    @AppStorage("inspirationEnabled") private var isEnabled = true

    var body: some View {
        List {
            Section {
                Toggle("Show Inspiration", isOn: $isEnabled)
            } footer: {
                Text("Display a motivational phrase at the top of your Today view.")
            }

            if isEnabled {
                Section("Tone") {
                    ForEach(InspirationPhrase.Tone.allCases, id: \.self) { toneOption in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(toneOption.rawValue.capitalized)
                                    .font(theme.typography.bodyFont)
                                Text(toneDescription(toneOption))
                                    .font(theme.typography.captionFont)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            Spacer()
                            if tone == toneOption.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(theme.colors.accent)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tone = toneOption.rawValue
                        }
                    }
                }
            }
        }
        .navigationTitle("Inspiration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toneDescription(_ tone: InspirationPhrase.Tone) -> String {
        switch tone {
        case .warm: "Encouraging and supportive"
        case .direct: "Concise and action-oriented"
        case .reflective: "Thoughtful and contemplative"
        }
    }
}
