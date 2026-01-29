import SwiftUI

struct PersonAvatarView: View {
    @Environment(\.theme) private var theme
    let name: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
                .frame(width: size, height: size)

            Text(initials)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private var avatarColor: Color {
        let hash = abs(name.hashValue)
        let colors: [Color] = [
            Color(hex: "5B4F3E"), Color(hex: "6B8F71"), Color(hex: "8B4513"),
            Color(hex: "7B61FF"), Color(hex: "D2691E"), Color(hex: "4A6741"),
            Color(hex: "6B5F53"), Color(hex: "B8860B"),
        ]
        return colors[hash % colors.count]
    }
}
