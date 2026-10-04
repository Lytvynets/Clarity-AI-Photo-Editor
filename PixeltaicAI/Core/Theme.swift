

import SwiftUI
import UIKit


extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    var hexString: String {
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((max(0, min(1, r)) * 255).rounded())
        let gi = Int((max(0, min(1, g)) * 255).rounded())
        let bi = Int((max(0, min(1, b)) * 255).rounded())
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}


enum Theme {
    static let bg0 = Color(hex: 0x09050F)
    static let bg1 = Color(hex: 0x160B2C)

    static let violet = Color(hex: 0x8B3DFF)
    static let fuchsia = Color(hex: 0xE24BFF)
    static let blue = Color(hex: 0x3D8BFF)
    static let cyan = Color(hex: 0x22D3EE)
    static let mint = Color(hex: 0x34E0A1)
    static let orange = Color(hex: 0xFF8A3D)
    static let pink = Color(hex: 0xFF4D8D)
    static let gold = Color(hex: 0xFFC14D)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)
    static let stroke = Color.white.opacity(0.10)
    static let danger = Color(hex: 0xFF5C6C)

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [violet, fuchsia], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var goldGradient: LinearGradient {
        LinearGradient(colors: [gold, orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func gradient(_ a: Color, _ b: Color) -> LinearGradient {
        LinearGradient(colors: [a, b], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}


extension Font {
    static func app(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        Font.system(style, design: .rounded).weight(weight)
    }
}


struct AppBackground: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.bg0, Theme.bg1], startPoint: .top, endPoint: .bottom)

            Circle()
                .fill(Theme.violet.opacity(0.34))
                .frame(width: 340, height: 340)
                .blur(radius: 90)
                .offset(x: drift ? -60 : -130, y: drift ? -250 : -310)

            Circle()
                .fill(Theme.fuchsia.opacity(0.20))
                .frame(width: 300, height: 300)
                .blur(radius: 90)
                .offset(x: drift ? 150 : 90, y: drift ? 280 : 330)

            Circle()
                .fill(Theme.blue.opacity(0.14))
                .frame(width: 240, height: 240)
                .blur(radius: 80)
                .offset(x: drift ? 120 : 160, y: drift ? -120 : -60)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}


struct GlassCard: ViewModifier {
    var radius: CGFloat = 22
    var fill: Double = 0.07

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.white.opacity(fill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(radius: CGFloat = 22, fill: Double = 0.07) -> some View {
        modifier(GlassCard(radius: radius, fill: fill))
    }
}


struct PrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = Theme.brandGradient
    var glow: Color = Theme.violet

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration, gradient: gradient, glow: glow)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let gradient: LinearGradient
    let glow: Color
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        configuration.label
            .font(.app(.headline, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(gradient))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 1))
            .shadow(color: glow.opacity(isEnabled ? 0.45 : 0), radius: 18, x: 0, y: 8)
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.app(.subheadline, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white.opacity(configuration.isPressed ? 0.16 : 0.09)))
            .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: configuration.isPressed)
    }
}


struct Chip: View {
    let title: String
    var icon: String? = nil
    var selected: Bool
    var locked: Bool = false
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.select()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                }
                Text(title).font(.app(.subheadline, weight: .semibold))
                if locked {
                    Image(systemName: "lock.fill").font(.system(size: 10, weight: .bold))
                        .foregroundColor(Theme.gold)
                }
            }
            .foregroundColor(selected ? .white : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule().fill(selected ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .overlay(Capsule().strokeBorder(selected ? Color.white.opacity(0.25) : Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.95))
        .animation(.easeOut(duration: 0.2), value: selected)
    }
}

struct ProBadge: View {
    var compact = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill").font(.system(size: compact ? 8 : 10, weight: .bold))
            Text("PRO").font(.system(size: compact ? 9 : 11, weight: .heavy, design: .rounded))
        }
        .foregroundColor(Color(hex: 0x2A1600))
        .padding(.horizontal, compact ? 6 : 8)
        .padding(.vertical, compact ? 3 : 4)
        .background(Capsule().fill(Theme.goldGradient))
    }
}

struct GradientTile: View {
    let symbol: String
    let colors: [Color]
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
            Image(systemName: symbol)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: (colors.first ?? Theme.violet).opacity(0.45), radius: 12, x: 0, y: 6)
    }
}

struct SectionTitle: View {
    let text: String
    var trailing: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(text)
                .font(.app(.title3, weight: .bold))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            if let trailing, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailing)
                        .font(.app(.subheadline, weight: .semibold))
                        .foregroundColor(Theme.fuchsia)
                }
            }
        }
    }
}

struct PanelLabel: View {
    let text: String
    var hint: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(Theme.textSecondary)
            if let hint {
                Text(hint)
                    .font(.app(.caption))
                    .foregroundColor(Theme.textTertiary)
            }
            Spacer()
        }
    }
}

struct CheckerboardView: View {
    var tile: CGFloat = 12

    var body: some View {
        Canvas { context, size in
            let cols = Int(ceil(size.width / tile))
            let rows = Int(ceil(size.height / tile))
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: 0x2A2438)))
            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 0 {
                    let rect = CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile, height: tile)
                    context.fill(Path(rect), with: .color(Color(hex: 0x3A3350)))
                }
            }
        }
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(colors: [.clear, Color.white.opacity(0.18), .clear],
                                   startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.6)
                        .offset(x: phase * geo.size.width * 1.6)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering() -> some View { modifier(Shimmer()) }
}
