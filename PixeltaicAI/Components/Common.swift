

import SwiftUI
import UIKit


struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let text = message {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.mint)
                        Text(text)
                            .font(.app(.subheadline, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Color(hex: 0x2A1B4D)))
                    .overlay(Capsule().strokeBorder(Theme.stroke, lineWidth: 1))
                    .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 8)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: text) {
                        try? await Task.sleep(nanoseconds: 2_300_000_000)
                        if !Task.isCancelled {
                            withAnimation { self.message = nil }
                        }
                    }
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}


struct IconButton: View {
    let symbol: String
    var size: CGFloat = 40
    var tint: Color = .white
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.white.opacity(0.10)))
                .overlay(Circle().strokeBorder(Theme.stroke, lineWidth: 1))
        }
        .buttonStyle(PressableStyle(scale: 0.9))
    }
}


struct OptionItem<Value: Hashable>: Identifiable {
    let title: String
    let value: Value
    var icon: String? = nil
    var locked: Bool = false

    var id: String { title }
}

struct OptionRow<Value: Hashable>: View {
    let items: [OptionItem<Value>]
    @Binding var selection: Value
    var onLockedTap: () -> Void = {}

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items) { item in
                    Chip(title: item.title,
                         icon: item.icon,
                         selected: selection == item.value,
                         locked: item.locked) {
                        if item.locked {
                            onLockedTap()
                        } else {
                            selection = item.value
                        }
                    }
                }
            }
            .padding(.horizontal, 1)
            .padding(.vertical, 2)
        }
    }
}


struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double = 1
    var suffix: String = ""

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.app(.subheadline, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(Int(value.rounded()))\(suffix)")
                    .font(.app(.subheadline, weight: .semibold))
                    .foregroundColor(value == 0 ? Theme.textTertiary : Theme.fuchsia)
                    .monospacedDigit()
            }
            Slider(value: $value, in: range, step: step)
                .tint(Theme.violet)
        }
    }
}


struct ErrorBanner: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.gold)
                .padding(.top, 1)
            Text(message)
                .font(.app(.footnote, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .padding(4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.danger.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Theme.danger.opacity(0.45), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}


struct TypewriterText: View {
    let phrases: [String]
    @State private var text = ""

    var body: some View {
        Text(text + "▍")
            .task { await loop() }
    }

    private func loop() async {
        guard !phrases.isEmpty else { return }
        var index = 0
        while !Task.isCancelled {
            let phrase = phrases[index % phrases.count]
            for character in phrase {
                if Task.isCancelled { return }
                text.append(character)
                try? await Task.sleep(nanoseconds: 55_000_000)
            }
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            while !text.isEmpty {
                if Task.isCancelled { return }
                text.removeLast()
                try? await Task.sleep(nanoseconds: 18_000_000)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            index += 1
        }
    }
}
