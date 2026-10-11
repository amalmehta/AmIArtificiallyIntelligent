import SwiftUI
import QuizCore

/// All colors, picked explicitly per color scheme so they also resolve inside `ImageRenderer`.
public struct Palette {
    public let background: Color
    public let card: Color
    public let cardHover: Color
    public let border: Color
    public let text: Color
    public let secondaryText: Color
    public let accent: Color
    public let human: Color
    public let machine: Color

    public static func forScheme(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? dark : light
    }

    static let light = Palette(
        background: Color(hue: 0.62, saturation: 0.05, brightness: 0.97),
        card: .white,
        cardHover: Color(hue: 0.62, saturation: 0.06, brightness: 0.94),
        border: Color(hue: 0.62, saturation: 0.10, brightness: 0.85),
        text: Color(hue: 0.62, saturation: 0.25, brightness: 0.15),
        secondaryText: Color(hue: 0.62, saturation: 0.12, brightness: 0.45),
        accent: Color(hue: 0.70, saturation: 0.70, brightness: 0.78),
        human: Color(hue: 0.38, saturation: 0.65, brightness: 0.62),
        machine: Color(hue: 0.83, saturation: 0.65, brightness: 0.72)
    )

    static let dark = Palette(
        background: Color(hue: 0.64, saturation: 0.25, brightness: 0.11),
        card: Color(hue: 0.64, saturation: 0.20, brightness: 0.17),
        cardHover: Color(hue: 0.64, saturation: 0.20, brightness: 0.23),
        border: Color(hue: 0.64, saturation: 0.15, brightness: 0.30),
        text: Color(hue: 0.62, saturation: 0.05, brightness: 0.95),
        secondaryText: Color(hue: 0.62, saturation: 0.10, brightness: 0.68),
        accent: Color(hue: 0.70, saturation: 0.50, brightness: 0.98),
        human: Color(hue: 0.38, saturation: 0.50, brightness: 0.85),
        machine: Color(hue: 0.83, saturation: 0.45, brightness: 0.95)
    )
}

/// Category colors. Related categories share a hue family (Thinking = blues, Heart = warm reds/oranges,
/// Machine Tells = purples), with hue and brightness spread far enough apart to tell siblings apart.
public enum CategoryColors {
    public static func color(_ category: QuizCore.Category, _ scheme: ColorScheme) -> Color {
        let dark = scheme == .dark
        switch category {
        // Thinking — blues
        case .reasoning:     return dark ? Color(hue: 0.61, saturation: 0.55, brightness: 1.00) : Color(hue: 0.62, saturation: 0.80, brightness: 0.72)
        case .commonSense:   return dark ? Color(hue: 0.52, saturation: 0.60, brightness: 0.88) : Color(hue: 0.52, saturation: 0.85, brightness: 0.58)
        // Heart — warm
        case .feelings:      return dark ? Color(hue: 0.99, saturation: 0.55, brightness: 1.00) : Color(hue: 0.99, saturation: 0.75, brightness: 0.80)
        case .selfAwareness: return dark ? Color(hue: 0.06, saturation: 0.65, brightness: 1.00) : Color(hue: 0.06, saturation: 0.85, brightness: 0.85)
        case .creativity:    return dark ? Color(hue: 0.12, saturation: 0.70, brightness: 0.95) : Color(hue: 0.11, saturation: 0.95, brightness: 0.70)
        // Machine Tells — purples
        case .hedging:       return dark ? Color(hue: 0.74, saturation: 0.50, brightness: 1.00) : Color(hue: 0.74, saturation: 0.65, brightness: 0.75)
        case .verbosity:     return dark ? Color(hue: 0.86, saturation: 0.50, brightness: 0.95) : Color(hue: 0.87, saturation: 0.75, brightness: 0.65)
        }
    }
}

/// A rounded, colored label for a category.
struct CategoryChip: View {
    let category: QuizCore.Category
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let c = CategoryColors.color(category, scheme)
        Text(category.title)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(c)
            .background(Capsule().fill(c.opacity(scheme == .dark ? 0.20 : 0.12)))
            .overlay(Capsule().strokeBorder(c.opacity(0.45), lineWidth: 1))
    }
}

/// Filled pill button that renders the same in the app and in `ImageRenderer`.
struct PillButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 11)
            .background(Capsule().fill(color.opacity(configuration.isPressed ? 0.8 : 1)))
            .contentShape(Capsule())
    }
}
