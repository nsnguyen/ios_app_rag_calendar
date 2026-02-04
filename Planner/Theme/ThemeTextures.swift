import SwiftUI

// MARK: - Theme Textures

struct ThemeTextures: Sendable {
    let paperBase: Color
    let paperLine: Color
    let paperLineOpacity: Double
    let bindingColor: Color
    let bindingShadow: Color

    // Month tab colors (12 months)
    let monthTabColors: [Color]

    // Pattern settings
    let showLines: Bool
    let lineSpacing: CGFloat

    // Paper grain/noise intensity (0-1)
    let grainIntensity: Double
}

// MARK: - Preset Textures

extension ThemeTextures {
    /// Warm, cream-colored paper with leather binding
    static var warm: ThemeTextures {
        let tabColors: [Color] = [
            Color(hex: "E57373"), // January - Red
            Color(hex: "F06292"), // February - Pink
            Color(hex: "81C784"), // March - Green
            Color(hex: "AED581"), // April - Light Green
            Color(hex: "FFD54F"), // May - Yellow
            Color(hex: "FFB74D"), // June - Orange
            Color(hex: "FF8A65"), // July - Deep Orange
            Color(hex: "4FC3F7"), // August - Light Blue
            Color(hex: "64B5F6"), // September - Blue
            Color(hex: "BA68C8"), // October - Purple
            Color(hex: "A1887F"), // November - Brown
            Color(hex: "90A4AE")  // December - Blue Grey
        ]
        return ThemeTextures(
            paperBase: Color(hex: "FFF8F0"),
            paperLine: Color(hex: "D4C5B5"),
            paperLineOpacity: 0.4,
            bindingColor: Color(hex: "8B7355"),
            bindingShadow: Color(hex: "5D4E3A"),
            monthTabColors: tabColors,
            showLines: true,
            lineSpacing: 24,
            grainIntensity: 0.03
        )
    }

    /// Calm, neutral paper with subtle earthy binding
    static var calm: ThemeTextures {
        let tabColors: [Color] = [
            Color(hex: "8D6E63"), // January
            Color(hex: "A1887F"), // February
            Color(hex: "6B8F71"), // March
            Color(hex: "81A87F"), // April
            Color(hex: "C5B358"), // May
            Color(hex: "D4A76A"), // June
            Color(hex: "C88D60"), // July
            Color(hex: "7BA3A8"), // August
            Color(hex: "6B8D9E"), // September
            Color(hex: "9575CD"), // October
            Color(hex: "8B7D6B"), // November
            Color(hex: "78909C")  // December
        ]
        return ThemeTextures(
            paperBase: Color(hex: "FDFBF8"),
            paperLine: Color(hex: "E0D5C9"),
            paperLineOpacity: 0.35,
            bindingColor: Color(hex: "6B5F53"),
            bindingShadow: Color(hex: "4A4038"),
            monthTabColors: tabColors,
            showLines: true,
            lineSpacing: 22,
            grainIntensity: 0.02
        )
    }

    /// Bold, dark mode paper with neon-ish accents
    static var bold: ThemeTextures {
        let tabColors: [Color] = [
            Color(hex: "FF6B6B"), // January
            Color(hex: "FF8EC4"), // February
            Color(hex: "50FA7B"), // March
            Color(hex: "8AE234"), // April
            Color(hex: "F1FA8C"), // May
            Color(hex: "FFB86C"), // June
            Color(hex: "FF7043"), // July
            Color(hex: "8BE9FD"), // August
            Color(hex: "6272A4"), // September
            Color(hex: "BD93F9"), // October
            Color(hex: "A88F76"), // November
            Color(hex: "6C7A89")  // December
        ]
        return ThemeTextures(
            paperBase: Color(hex: "1A1A2E"),
            paperLine: Color(hex: "333355"),
            paperLineOpacity: 0.5,
            bindingColor: Color(hex: "7B61FF"),
            bindingShadow: Color(hex: "4A3DB3"),
            monthTabColors: tabColors,
            showLines: true,
            lineSpacing: 20,
            grainIntensity: 0.04
        )
    }

    /// Minimal, clean paper following system colors
    static var minimal: ThemeTextures {
        let tabColors: [Color] = [
            Color.red,
            Color.pink,
            Color.green,
            Color.mint,
            Color.yellow,
            Color.orange,
            Color.brown,
            Color.cyan,
            Color.blue,
            Color.purple,
            Color.indigo,
            Color.gray
        ]
        return ThemeTextures(
            paperBase: Color(uiColor: .secondarySystemBackground),
            paperLine: Color(uiColor: .separator),
            paperLineOpacity: 0.3,
            bindingColor: Color(uiColor: .systemGray3),
            bindingShadow: Color(uiColor: .systemGray4),
            monthTabColors: tabColors,
            showLines: false,
            lineSpacing: 24,
            grainIntensity: 0
        )
    }
}

// MARK: - Paper Texture View Modifier

struct PaperTextureModifier: ViewModifier {
    @Environment(\.theme) private var theme
    let showLines: Bool

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base paper color
                    theme.textures.paperBase

                    // Paper grain overlay
                    if theme.textures.grainIntensity > 0 {
                        PaperGrainView(intensity: theme.textures.grainIntensity)
                    }

                    // Horizontal lines
                    if showLines && theme.textures.showLines {
                        PaperLinesView(
                            lineColor: theme.textures.paperLine,
                            opacity: theme.textures.paperLineOpacity,
                            spacing: theme.textures.lineSpacing
                        )
                    }
                }
            }
    }
}

// MARK: - Paper Grain View (subtle noise)

struct PaperGrainView: View {
    let intensity: Double

    var body: some View {
        Canvas { context, size in
            // Create a subtle noise pattern
            let step: CGFloat = 4
            for x in stride(from: 0, to: size.width, by: step) {
                for y in stride(from: 0, to: size.height, by: step) {
                    let noise = Double.random(in: 0...1)
                    if noise > 0.5 {
                        let opacity = (noise - 0.5) * 2 * intensity
                        let rect = CGRect(x: x, y: y, width: step, height: step)
                        context.fill(
                            Path(ellipseIn: rect.insetBy(dx: step * 0.3, dy: step * 0.3)),
                            with: .color(.black.opacity(opacity))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Paper Lines View

struct PaperLinesView: View {
    let lineColor: Color
    let opacity: Double
    let spacing: CGFloat

    var body: some View {
        Canvas { context, size in
            let startY: CGFloat = 60 // Leave room for header
            var y = startY

            while y < size.height {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(lineColor.opacity(opacity)), lineWidth: 0.5)
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - View Extension

extension View {
    func paperTexture(showLines: Bool = true) -> some View {
        modifier(PaperTextureModifier(showLines: showLines))
    }
}
