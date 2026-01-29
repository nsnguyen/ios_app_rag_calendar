import SwiftUI

struct FormattingToolbar: View {
    let onAction: (FormattingAction) -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button {
                onAction(.bold)
            } label: {
                Image(systemName: "bold")
                    .font(.body.weight(.medium))
            }

            Button {
                onAction(.italic)
            } label: {
                Image(systemName: "italic")
                    .font(.body.weight(.medium))
            }

            Button {
                onAction(.heading)
            } label: {
                Image(systemName: "textformat.size.larger")
                    .font(.body.weight(.medium))
            }

            Button {
                onAction(.checklist)
            } label: {
                Image(systemName: "checklist")
                    .font(.body.weight(.medium))
            }

            Spacer()

            Button {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.body.weight(.medium))
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .foregroundStyle(Color(.tintColor))
    }
}
